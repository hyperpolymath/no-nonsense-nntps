// SPDX-License-Identifier: PMPL-1.0-or-later

type article = {
  headers: Dict.t<string>,
  body: string,
}

type connectionStatus =
  | Disconnected
  | Connecting
  | Connected(string) // host

type model = {
  connectionStatus: connectionStatus,
  host: string,
  port: int,
  articleId: string,
  article: option<article>,
  error: option<string>,
}

type msg =
  | UpdateHost(string)
  | UpdatePort(string)
  | UpdateArticleId(string)
  | Connect
  | ConnectSuccess
  | ConnectFailure(string)
  | FetchArticle
  | ArticleFetched(article)
  | FetchFailure(string)
