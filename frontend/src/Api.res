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
