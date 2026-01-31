// SPDX-License-Identifier: PMPL-1.0-or-later

open Types

let initialModel = {
  connectionStatus: Disconnected,
  host: "news.eternal-september.org",
  port: 563,
  articleId: "<test@example.com>",
  article: None,
  error: None,
}

let update = (model, msg) => {
  switch msg {
  | UpdateHost(host) => {...model, host}
  | UpdatePort(portStr) => {
      ...model,
      port: portStr->Int.fromString->Option.getOr(563),
    }
  | UpdateArticleId(articleId) => {...model, articleId}
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
  | FetchArticle => {...model, error: None}
  | ArticleFetched(article) => {...model, article: Some(article)}
  | FetchFailure(error) => {...model, error: Some(error)}
  }
}

@react.component
let make = () => {
  let (model, setModel) = React.useState(() => initialModel)

  let dispatch = msg => setModel(model => update(model, msg))

  let handleConnect = evt => {
    evt->ReactEvent.Mouse.preventDefault
    dispatch(Connect)
    Api.connect(
      ~host=model.host,
      ~port=model.port,
      ~onSuccess=() => dispatch(ConnectSuccess),
      ~onFailure=error => dispatch(ConnectFailure(error)),
    )
  }

  let handleFetchArticle = evt => {
    evt->ReactEvent.Mouse.preventDefault
    dispatch(FetchArticle)
    Api.fetchArticle(
      ~articleId=model.articleId,
      ~onSuccess=article => dispatch(ArticleFetched(article)),
      ~onFailure=error => dispatch(FetchFailure(error)),
    )
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

  <div>
    <h1> {React.string("No-Nonsense NNTPS Reader")} </h1>
    <div className={statusClass}> {React.string(statusText)} </div>
    {switch model.error {
    | Some(error) => <div className="error"> {React.string(error)} </div>
    | None => React.null
    }}
    <div className="connection-form">
      <h2> {React.string("Connection")} </h2>
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
    {switch model.connectionStatus {
    | Connected(_) =>
      <div className="connection-form">
        <h2> {React.string("Fetch Article")} </h2>
        <form onSubmit={handleFetchArticle}>
          <input
            type_="text"
            placeholder="Article Message-ID"
            value={model.articleId}
            onChange={evt => dispatch(UpdateArticleId(evt->ReactEvent.Form.target["value"]))}
            style={{width: "400px"}}
          />
          <button type_="submit"> {React.string("Fetch")} </button>
        </form>
      </div>
    | _ => React.null
    }}
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
    | None => React.null
    }}
  </div>
}
