// SPDX-License-Identifier: PMPL-1.0-or-later

open Types

let initialModel = {
  connectionStatus: Disconnected,
  host: "news.eternal-september.org",
  port: 563,
  groups: [],
  selectedGroup: None,
  articles: [],
  article: None,
  error: None,
  loadingGroups: false,
  loadingArticles: false,
}

let update = (model, msg) => {
  switch msg {
  | UpdateHost(host) => {...model, host}
  | UpdatePort(portStr) => {
      ...model,
      port: portStr->Int.fromString->Option.getOr(563),
    }
  | Connect => {
      ...model,
      connectionStatus: Connecting,
      error: None,
    }
  | ConnectSuccess => {
      ...model,
      connectionStatus: Connected(model.host),
    }
  | ConnectFailure(error) => {
      ...model,
      connectionStatus: Disconnected,
      error: Some(error),
    }
  | FetchGroups => {...model, loadingGroups: true, error: None}
  | GroupsFetched(groups) => {...model, groups, loadingGroups: false}
  | GroupsFetchFailure(error) => {...model, loadingGroups: false, error: Some(error)}
  | SelectGroup(groupName) => {
      ...model,
      selectedGroup: Some(groupName),
      loadingArticles: true,
      articles: [],
      article: None,
      error: None,
    }
  | GroupSelected(name, _count, first, last) => {
      ...model,
      selectedGroup: Some(name),
    }
  | ArticlesFetched(articles) => {...model, articles, loadingArticles: false}
  | ArticlesFetchFailure(error) => {...model, loadingArticles: false, error: Some(error)}
  | SelectArticle(groupName, messageId) => {
      ...model,
      selectedGroup: Some(groupName),
      error: None,
    }
  | ArticleFetched(article) => {...model, article: Some(article)}
  | FetchFailure(error) => {...model, error: Some(error)}
  }
}

@react.component
let make = () => {
  let (model, setModel) = React.useState(() => initialModel)
  let (currentRoute, navigate) = Router.useRouter()

  let dispatch = msg => setModel(model => update(model, msg))

  // Handle route changes
  React.useEffect(() => {
    switch currentRoute {
    | Router.Groups =>
      if model.connectionStatus != Disconnected && model.groups->Array.length == 0 {
        dispatch(FetchGroups)
        Api.fetchGroups(
          ~onSuccess=groups => dispatch(GroupsFetched(groups)),
          ~onFailure=error => dispatch(GroupsFetchFailure(error)),
        )
      }
    | Router.GroupView(groupName) => {
        dispatch(SelectGroup(groupName))
        Api.selectGroup(
          ~groupName,
          ~onSuccess=(name, count, first, last) => {
            dispatch(GroupSelected(name, count, first, last))
            // Fetch recent articles (last 100)
            let articleFirst = max(last - 100, first)
            Api.fetchArticles(
              ~groupName=name,
              ~first=articleFirst,
              ~last,
              ~onSuccess=articles => dispatch(ArticlesFetched(articles)),
              ~onFailure=error => dispatch(ArticlesFetchFailure(error)),
            )
          },
          ~onFailure=error => dispatch(GroupsFetchFailure(error)),
        )
      }
    | Router.ArticleView(groupName, messageId) => {
        dispatch(SelectArticle(groupName, messageId))
        Api.fetchArticle(
          ~articleId=messageId,
          ~onSuccess=article => dispatch(ArticleFetched(article)),
          ~onFailure=error => dispatch(FetchFailure(error)),
        )
      }
    | Router.Home => ()
    }

    None
  }, [currentRoute])

  let handleConnect = evt => {
    evt->ReactEvent.Mouse.preventDefault
    dispatch(Connect)
    Api.connect(
      ~host=model.host,
      ~port=model.port,
      ~onSuccess=() => {
        dispatch(ConnectSuccess)
        Router.push(Router.Groups)
      },
      ~onFailure=error => dispatch(ConnectFailure(error)),
    )
  }

  let handleSelectGroup = groupName => {
    Router.push(Router.GroupView(groupName))
  }

  let handleSelectArticle = messageId => {
    switch model.selectedGroup {
    | Some(groupName) => Router.push(Router.ArticleView(groupName, messageId))
    | None => ()
    }
  }

  let statusClass = switch model.connectionStatus {
  | Disconnected => "status disconnected"
  | Connecting => "status connecting"
  | Connected(_) => "status connected"
  }

  let statusText = switch model.connectionStatus {
  | Disconnected => "Disconnected"
  | Connecting => "Connecting..."
  | Connected(host) => `Connected to ${host}`
  }

  <div className="app">
    <header className="app-header">
      <h1 onClick={_ => Router.push(Router.Home)}> {React.string("No-Nonsense NNTPS")} </h1>
      <div className={statusClass}> {React.string(statusText)} </div>
    </header>
    {switch model.error {
    | Some(error) => <div className="error"> {React.string(error)} </div>
    | None => React.null
    }}
    {switch currentRoute {
    | Router.Home =>
      <div className="connection-form">
        <h2> {React.string("Connect to NNTPS Server")} </h2>
        <form onSubmit={handleConnect}>
          <input
            type_="text"
            placeholder="NNTPS Server"
            value={model.host}
            onChange={evt => dispatch(UpdateHost(evt->ReactEvent.Form.target["value"]))}
          />
          <input
            type_="number"
            placeholder="Port"
            value={model.port->Int.toString}
            onChange={evt => dispatch(UpdatePort(evt->ReactEvent.Form.target["value"]))}
          />
          <button type_="submit" disabled={model.connectionStatus == Connecting}>
            {React.string("Connect")}
          </button>
        </form>
      </div>

    | Router.Groups =>
      <NewsgroupList
        groups={model.groups} onSelectGroup={handleSelectGroup} loading={model.loadingGroups}
      />

    | Router.GroupView(groupName) =>
      <div className="group-view">
        <ArticleList
          groupName
          articles={model.articles}
          onSelectArticle={handleSelectArticle}
          loading={model.loadingArticles}
        />
      </div>

    | Router.ArticleView(groupName, _messageId) =>
      <div className="article-view-container">
        <button className="back-button" onClick={_ => Router.push(Router.GroupView(groupName))}>
          {React.string("← Back to Articles")}
        </button>
        {switch model.article {
        | Some(article) =>
          <div className="article">
            <div className="article-header">
              <h2> {React.string("Article")} </h2>
              <dl>
                {article.headers
                ->Dict.toArray
                ->Array.map(((key, value)) =>
                  <React.Fragment key>
                    <dt> {React.string(key)} </dt> <dd> {React.string(value)} </dd>
                  </React.Fragment>
                )
                ->React.array}
              </dl>
            </div>
            <div className="article-body"> {React.string(article.body)} </div>
          </div>
        | None => <div className="loading"> {React.string("Loading article...")} </div>
        }}
      </div>
    }}
  </div>
}
