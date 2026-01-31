// SPDX-License-Identifier: PMPL-1.0-or-later

@react.component
let make = (
  ~groupName: string,
  ~articles: array<Types.articleOverview>,
  ~onSelectArticle: string => unit,
  ~loading: bool,
) => {
  <div className="article-list">
    <div className="article-list-header">
      <h2> {React.string(`Articles in ${groupName}`)} </h2>
      <div className="article-count">
        {React.string(`${articles->Array.length->Int.toString} articles`)}
      </div>
    </div>
    {if loading {
      <div className="loading"> {React.string("Loading articles...")} </div>
    } else if articles->Array.length == 0 {
      <div className="no-results"> {React.string("No articles in this group")} </div>
    } else {
      <div className="articles-table">
        <div className="articles-table-header">
          <div className="col-number"> {React.string("#")} </div>
          <div className="col-subject"> {React.string("Subject")} </div>
          <div className="col-from"> {React.string("From")} </div>
          <div className="col-date"> {React.string("Date")} </div>
        </div>
        {articles
        ->Array.map(article => {
          <div
            key={article.messageId}
            className="article-row"
            onClick={_ => onSelectArticle(article.messageId)}>
            <div className="col-number"> {React.string(article.number->Int.toString)} </div>
            <div className="col-subject"> {React.string(article.subject)} </div>
            <div className="col-from"> {React.string(article.from)} </div>
            <div className="col-date"> {React.string(article.date)} </div>
          </div>
        })
        ->React.array}
      </div>
    }}
  </div>
}
