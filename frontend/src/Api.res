// SPDX-License-Identifier: PMPL-1.0-or-later

let apiBase = "http://localhost:4000"

let connect = (~host: string, ~port: int, ~onSuccess, ~onFailure) => {
  let connectImpl = %raw(`
    async function(apiBase, host, port) {
      const response = await fetch(apiBase + '/api/connect', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ host, port })
      });
      if (response.ok) {
        return { ok: true };
      } else {
        const text = await response.text();
        return { ok: false, error: text };
      }
    }
  `)

  connectImpl(apiBase, host, port)
  ->Promise.then(result => {
    let r = result->Obj.magic
    if r["ok"] {
      onSuccess()
    } else {
      onFailure(r["error"])
    }
    Promise.resolve()
  })
  ->Promise.catch(_ => {
    onFailure("Network error")
    Promise.resolve()
  })
  ->ignore
}

let fetchGroups = (~onSuccess, ~onFailure) => {
  let impl = %raw(`
    async function(apiBase) {
      const response = await fetch(apiBase + '/api/groups');
      if (response.ok) {
        const data = await response.json();
        return { ok: true, groups: data.groups || [] };
      } else {
        return { ok: false, error: await response.text() };
      }
    }
  `)

  impl(apiBase)
  ->Promise.then(result => {
    let r = result->Obj.magic
    if r["ok"] {
      let groups = r["groups"]->Obj.magic
      onSuccess(groups)
    } else {
      onFailure(r["error"])
    }
    Promise.resolve()
  })
  ->Promise.catch(_ => {
    onFailure("Network error")
    Promise.resolve()
  })
  ->ignore
}

let selectGroup = (~groupName: string, ~onSuccess, ~onFailure) => {
  let impl = %raw(`
    async function(apiBase, groupName) {
      const response = await fetch(apiBase + '/api/groups/' + groupName);
      if (response.ok) {
        const data = await response.json();
        return { ok: true, data };
      } else {
        return { ok: false, error: await response.text() };
      }
    }
  `)

  impl(apiBase, groupName)
  ->Promise.then(result => {
    let r = result->Obj.magic
    if r["ok"] {
      let data = r["data"]->Obj.magic
      onSuccess(data["name"], data["count"], data["first"], data["last"])
    } else {
      onFailure(r["error"])
    }
    Promise.resolve()
  })
  ->Promise.catch(_ => {
    onFailure("Network error")
    Promise.resolve()
  })
  ->ignore
}

let fetchArticles = (~groupName: string, ~first: option<int>=?, ~last: option<int>=?, ~onSuccess, ~onFailure) => {
  let impl = %raw(`
    async function(apiBase, groupName, first, last) {
      let url = apiBase + '/api/groups/' + groupName + '/articles';
      if (first !== undefined && last !== undefined) {
        url += '?first=' + first + '&last=' + last;
      }
      const response = await fetch(url);
      if (response.ok) {
        const data = await response.json();
        return { ok: true, articles: data.articles || [] };
      } else {
        return { ok: false, error: await response.text() };
      }
    }
  `)

  impl(apiBase, groupName, first->Option.getOr(0->Obj.magic), last->Option.getOr(0->Obj.magic))
  ->Promise.then(result => {
    let r = result->Obj.magic
    if r["ok"] {
      let articles = r["articles"]->Obj.magic
      onSuccess(articles)
    } else {
      onFailure(r["error"])
    }
    Promise.resolve()
  })
  ->Promise.catch(_ => {
    onFailure("Network error")
    Promise.resolve()
  })
  ->ignore
}

let fetchArticle = (~articleId: string, ~onSuccess, ~onFailure) => {
  let impl = %raw(`
    async function(apiBase, articleId) {
      const response = await fetch(apiBase + '/api/articles/' + articleId);
      if (response.ok) {
        const data = await response.json();
        return { ok: true, article: data };
      } else {
        return { ok: false, error: await response.text() };
      }
    }
  `)

  impl(apiBase, articleId)
  ->Promise.then(result => {
    let r = result->Obj.magic
    if r["ok"] {
      let article = r["article"]->Obj.magic
      onSuccess({Types.headers: article["headers"]->Obj.magic, body: article["body"]})
    } else {
      onFailure(r["error"])
    }
    Promise.resolve()
  })
  ->Promise.catch(_ => {
    onFailure("Network error")
    Promise.resolve()
  })
  ->ignore
}
