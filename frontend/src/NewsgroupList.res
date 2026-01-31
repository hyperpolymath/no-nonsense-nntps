// SPDX-License-Identifier: PMPL-1.0-or-later

@react.component
let make = (~groups: array<Types.groupInfo>, ~onSelectGroup: string => unit, ~loading: bool) => {
  let (searchTerm, setSearchTerm) = React.useState(() => "")

  let filteredGroups =
    groups->Array.filter(group => {
      searchTerm == "" ||
        group.name->String.toLowerCase->String.includes(searchTerm->String.toLowerCase)
    })

  <div className="newsgroup-list">
    <div className="newsgroup-list-header">
      <h2> {React.string("Newsgroups")} </h2>
      <input
        type_="text"
        placeholder="Search newsgroups..."
        value={searchTerm}
        onChange={evt => setSearchTerm(_ => evt->ReactEvent.Form.target["value"])}
        className="search-input"
      />
      <div className="group-count">
        {React.string(
          `Showing ${filteredGroups->Array.length->Int.toString} of ${groups->Array.length->Int.toString} groups`,
        )}
      </div>
    </div>
    {if loading {
      <div className="loading"> {React.string("Loading newsgroups...")} </div>
    } else if filteredGroups->Array.length == 0 {
      <div className="no-results">
        {React.string(
          if searchTerm == "" {
            "No newsgroups available. Connect to a server first."
          } else {
            `No groups matching "${searchTerm}"`
          },
        )}
      </div>
    } else {
      <div className="group-list">
        {filteredGroups
        ->Array.map(group => {
          let articleCount = group.high - group.low

          <div
            key={group.name}
            className="group-item"
            onClick={_ => onSelectGroup(group.name)}>
            <div className="group-name"> {React.string(group.name)} </div>
            <div className="group-meta">
              <span className="article-count">
                {React.string(`${articleCount->Int.toString} articles`)}
              </span>
              <span className="group-status"> {React.string(group.status)} </span>
            </div>
          </div>
        })
        ->React.array}
      </div>
    }}
  </div>
}
