// SPDX-License-Identifier: PMPL-1.0-or-later

let apiBase = "http://localhost:4000"

let connect = (~host: string, ~port: int, ~onSuccess, ~onFailure) => {
  let body = {"host": host, "port": port}->JSON.stringifyAny->Option.getExn

  Fetch.fetch(
    `${apiBase}/api/connect`,
    {
      method: #POST,
      headers: {"Content-Type": "application/json"},
      body,
    },
  )
  ->Promise.then(response => {
    if response->Fetch.Response.ok {
      onSuccess()
      Promise.resolve()
    } else {
      response
      ->Fetch.Response.text
      ->Promise.then(text => {
        onFailure(`HTTP ${response->Fetch.Response.status->Int.toString}: ${text}`)
        Promise.resolve()
      })
    }
  })
  ->Promise.catch(error => {
    onFailure(`Network error: ${error->JSON.stringifyAny->Option.getOr("unknown")}`)
    Promise.resolve()
  })
  ->ignore
}

let fetchGroups = (~onSuccess, ~onFailure) => {
  Fetch.fetch(`${apiBase}/api/groups`)
  ->Promise.then(response => {
    if response->Fetch.Response.ok {
      response
      ->Fetch.Response.json
      ->Promise.then(json => {
        switch json->JSON.Decode.object {
        | Some(obj) => {
            let groups =
              obj
              ->Dict.get("groups")
              ->Option.flatMap(JSON.Decode.array)
              ->Option.getOr([])
              ->Array.map(groupJson => {
                switch groupJson->JSON.Decode.object {
                | Some(g) => {
                    name: g->Dict.get("name")->Option.flatMap(JSON.Decode.string)->Option.getOr(""),
                    high: g
                    ->Dict.get("high")
                    ->Option.flatMap(JSON.Decode.float)
                    ->Option.map(Float.toInt)
                    ->Option.getOr(0),
                    low: g
                    ->Dict.get("low")
                    ->Option.flatMap(JSON.Decode.float)
                    ->Option.map(Float.toInt)
                    ->Option.getOr(0),
                    status: g
                    ->Dict.get("status")
                    ->Option.flatMap(JSON.Decode.string)
                    ->Option.getOr(""),
                  }
                | None => {name: "", high: 0, low: 0, status: ""}
                }
              })
              ->Array.filter(g => g.name != "")

            onSuccess(groups)
          }
        | None => onFailure("Invalid response format")
        }
        Promise.resolve()
      })
    } else {
      response
      ->Fetch.Response.text
      ->Promise.then(text => {
        onFailure(`HTTP ${response->Fetch.Response.status->Int.toString}: ${text}`)
        Promise.resolve()
      })
    }
  })
  ->Promise.catch(error => {
    onFailure(`Network error: ${error->JSON.stringifyAny->Option.getOr("unknown")}`)
    Promise.resolve()
  })
  ->ignore
}

let selectGroup = (~groupName: string, ~onSuccess, ~onFailure) => {
  Fetch.fetch(`${apiBase}/api/groups/${groupName}`)
  ->Promise.then(response => {
    if response->Fetch.Response.ok {
      response
      ->Fetch.Response.json
      ->Promise.then(json => {
        switch json->JSON.Decode.object {
        | Some(obj) => {
            let name =
              obj->Dict.get("name")->Option.flatMap(JSON.Decode.string)->Option.getOr(groupName)
            let count =
              obj->Dict.get("count")->Option.flatMap(JSON.Decode.float)->Option.map(Float.toInt)->Option.getOr(
                0,
              )
            let first =
              obj->Dict.get("first")->Option.flatMap(JSON.Decode.float)->Option.map(Float.toInt)->Option.getOr(
                0,
              )
            let last =
              obj->Dict.get("last")->Option.flatMap(JSON.Decode.float)->Option.map(Float.toInt)->Option.getOr(
                0,
              )

            onSuccess(name, count, first, last)
          }
        | None => onFailure("Invalid response format")
        }
        Promise.resolve()
      })
    } else {
      response
      ->Fetch.Response.text
      ->Promise.then(text => {
        onFailure(`HTTP ${response->Fetch.Response.status->Int.toString}: ${text}`)
        Promise.resolve()
      })
    }
  })
  ->Promise.catch(error => {
    onFailure(`Network error: ${error->JSON.stringifyAny->Option.getOr("unknown")}`)
    Promise.resolve()
  })
  ->ignore
}

let fetchArticles = (~groupName: string, ~first: option<int>=?, ~last: option<int>=?, ~onSuccess, ~onFailure) => {
  let url = switch (first, last) {
  | (Some(f), Some(l)) => `${apiBase}/api/groups/${groupName}/articles?first=${f->Int.toString}&last=${l->Int.toString}`
  | _ => `${apiBase}/api/groups/${groupName}/articles`
  }

  Fetch.fetch(url)
  ->Promise.then(response => {
    if response->Fetch.Response.ok {
      response
      ->Fetch.Response.json
      ->Promise.then(json => {
        switch json->JSON.Decode.object {
        | Some(obj) => {
            let articles =
              obj
              ->Dict.get("articles")
              ->Option.flatMap(JSON.Decode.array)
              ->Option.getOr([])
              ->Array.map(articleJson => {
                switch articleJson->JSON.Decode.object {
                | Some(a) => {
                    number: a
                    ->Dict.get("number")
                    ->Option.flatMap(JSON.Decode.float)
                    ->Option.map(Float.toInt)
                    ->Option.getOr(0),
                    subject: a
                    ->Dict.get("subject")
                    ->Option.flatMap(JSON.Decode.string)
                    ->Option.getOr(""),
                    from: a->Dict.get("from")->Option.flatMap(JSON.Decode.string)->Option.getOr(""),
                    date: a->Dict.get("date")->Option.flatMap(JSON.Decode.string)->Option.getOr(""),
                    messageId: a
                    ->Dict.get("message_id")
                    ->Option.flatMap(JSON.Decode.string)
                    ->Option.getOr(""),
                  }
                | None => {number: 0, subject: "", from: "", date: "", messageId: ""}
                }
              })
              ->Array.filter(a => a.messageId != "")

            onSuccess(articles)
          }
        | None => onFailure("Invalid response format")
        }
        Promise.resolve()
      })
    } else {
      response
      ->Fetch.Response.text
      ->Promise.then(text => {
        onFailure(`HTTP ${response->Fetch.Response.status->Int.toString}: ${text}`)
        Promise.resolve()
      })
    }
  })
  ->Promise.catch(error => {
    onFailure(`Network error: ${error->JSON.stringifyAny->Option.getOr("unknown")}`)
    Promise.resolve()
  })
  ->ignore
}

let fetchArticle = (~articleId: string, ~onSuccess, ~onFailure) => {
  Fetch.fetch(`${apiBase}/api/articles/${articleId}`)
  ->Promise.then(response => {
    if response->Fetch.Response.ok {
      response
      ->Fetch.Response.json
      ->Promise.then(json => {
        switch json->JSON.Decode.object {
        | Some(obj) => {
            let headers =
              obj
              ->Dict.get("headers")
              ->Option.flatMap(JSON.Decode.object)
              ->Option.getOr(Dict.make())
              ->Dict.toArray
              ->Array.map(((k, v)) => (k, v->JSON.Decode.string->Option.getOr("")))
              ->Dict.fromArray

            let body = obj->Dict.get("body")->Option.flatMap(JSON.Decode.string)->Option.getOr("")

            onSuccess({Types.headers, body})
          }
        | None => onFailure("Invalid response format")
        }
        Promise.resolve()
      })
    } else {
      response
      ->Fetch.Response.text
      ->Promise.then(text => {
        onFailure(`HTTP ${response->Fetch.Response.status->Int.toString}: ${text}`)
        Promise.resolve()
      })
    }
  })
  ->Promise.catch(error => {
    onFailure(`Network error: ${error->JSON.stringifyAny->Option.getOr("unknown")}`)
    Promise.resolve()
  })
  ->ignore
}
