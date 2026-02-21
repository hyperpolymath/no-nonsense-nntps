// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * NNTPS Frontend Router — Type-Safe Navigation (ReScript).
 *
 * This module implements the client-side routing for the NNTPS application. 
 * It maps URL paths to semantic `route` variants, ensuring that 
 * navigation is verified at compile time.
 */

// ROUTES: Formal specification of the application's view-state space.
type route =
  | Home
  | Groups
  | GroupView(string)           // Path: /groups/[name]
  | ArticleView(string, string) // Path: /groups/[name]/article/[id]

/**
 * PARSER: Transforms a physical window.location.pathname into a `route`.
 * Handles 404s by falling back to the `Home` state.
 */
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

/**
 * DISPATCHER: Updates the browser history and triggers a UI re-render.
 */
let push = (route: route) => {
  let path = routeToPath(route)
  %raw(`window.history.pushState({}, "", path)`)
  // SIGNAL: Manually trigger popstate to notify the React hook.
  %raw(`window.dispatchEvent(new PopStateEvent('popstate'))`)
}

/**
 * HOOK: Provides the current route and navigation function to React components.
 */
let useRouter = () => {
  let (route, setRoute) = React.useState(() => getCurrentRoute())
  // ... [Event listener setup for 'popstate']
  (route, push)
}
