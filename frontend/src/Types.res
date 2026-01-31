// SPDX-License-Identifier: PMPL-1.0-or-later

type article = {
  headers: Dict.t<string>,
  body: string,
}

type groupInfo = {
  name: string,
  high: int,
  low: int,
  status: string,
}

type articleOverview = {
  number: int,
  subject: string,
  from: string,
  date: string,
  messageId: string,
}

type connectionStatus =
  | Disconnected
  | Connecting
  | Connected(string) // host

type model = {
  connectionStatus: connectionStatus,
  host: string,
  port: int,
  groups: array<groupInfo>,
  selectedGroup: option<string>,
  articles: array<articleOverview>,
  article: option<article>,
  error: option<string>,
  loadingGroups: bool,
  loadingArticles: bool,
}

type msg =
  | UpdateHost(string)
  | UpdatePort(string)
  | Connect
  | ConnectSuccess
  | ConnectFailure(string)
  | FetchGroups
  | GroupsFetched(array<groupInfo>)
  | GroupsFetchFailure(string)
  | SelectGroup(string)
  | GroupSelected(string, int, int, int) // name, count, first, last
  | ArticlesFetched(array<articleOverview>)
  | ArticlesFetchFailure(string)
  | SelectArticle(string, string) // groupName, messageId
  | ArticleFetched(article)
  | FetchFailure(string)
