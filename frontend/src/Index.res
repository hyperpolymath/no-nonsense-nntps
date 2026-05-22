// SPDX-License-Identifier: MPL-2.0

switch ReactDOM.querySelector("#root") {
| Some(root) => ReactDOM.Client.createRoot(root)->ReactDOM.Client.Root.render(<App />)
| None => Console.error("Root element not found")
}
