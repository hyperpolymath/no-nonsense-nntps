// SPDX-License-Identifier: PMPL-1.0-or-later

type route =
  | Home
  | Groups
  | GroupView(string)
  | ArticleView(string, string) // (groupName, articleId)

let parseRoute = (path: string): route => {
  let parts = path->String.split("/")->Array.filter(p => p != "")

  switch parts {
  | [] => Home
  | ["groups"] => Groups
  | ["groups", groupName] => GroupView(groupName)
  | ["groups", groupName, "article", articleId] => ArticleView(groupName, articleId)
  | _ => Home
  }
}

let routeToPath = (route: route): string => {
  switch route {
  | Home => "/"
  | Groups => "/groups"
  | GroupView(groupName) => `/groups/${groupName}`
  | ArticleView(groupName, articleId) => `/groups/${groupName}/article/${articleId}`
  }
}

let push = (route: route) => {
  let path = routeToPath(route)
  %raw(`window.history.pushState({}, "", path)`)
  // Dispatch popstate event manually for push
  %raw(`window.dispatchEvent(new PopStateEvent('popstate'))`)
}

let replace = (route: route) => {
  let path = routeToPath(route)
  %raw(`window.history.replaceState({}, "", path)`)
}

let getCurrentRoute = (): route => {
  let path = %raw(`window.location.pathname`)
  parseRoute(path)
}

let useRouter = () => {
  let (route, setRoute) = React.useState(() => getCurrentRoute())

  React.useEffect(() => {
    let handlePopState = %raw(`
      function() {
        return window.location.pathname
      }
    `)

    let listener = _evt => {
      setRoute(_ => parseRoute(handlePopState()))
    }

    %raw(`window.addEventListener('popstate', listener)`)

    Some(() => %raw(`window.removeEventListener('popstate', listener)`))
  }, [])

  (route, push)
}
