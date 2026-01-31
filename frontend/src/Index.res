// SPDX-License-Identifier: PMPL-1.0-or-later

switch ReactDOM.querySelector("#root") {
| Some(root) => ReactDOM.Client.createRoot(root)->ReactDOM.Client.Root.render(<App />)
| None => Console.error("Root element not found")
}
