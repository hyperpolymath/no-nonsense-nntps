# SPDX-License-Identifier: PMPL-1.0-or-later
# Benchee benchmarks for the NoNonsenseNntps HTTP API layer.
#
# Run with:   mix run bench/server_bench.exs
#
# These benchmarks measure the overhead of the Plug pipeline itself
# without requiring a live NNTP connection. They serve as a baseline
# to detect regressions in middleware or routing performance.

alias NoNonsenseNntps.API

opts = API.init([])

# Pre-built Plug.Conn values reused across iterations.
health_conn     = Plug.Test.conn(:get, "/api/health")
groups_conn     = Plug.Test.conn(:get, "/api/groups")
article_conn    = Plug.Test.conn(:get, "/api/articles/test%40example.com")
group_sel_conn  = Plug.Test.conn(:get, "/api/groups/comp.lang.elixir")
not_found_conn  = Plug.Test.conn(:get, "/api/nonexistent")

connect_body    = Jason.encode!(%{"host" => "localhost", "port" => 563})
connect_conn    =
  Plug.Test.conn(:post, "/api/connect", connect_body)
  |> Plug.Conn.put_req_header("content-type", "application/json")

Benchee.run(
  %{
    # --- Health check: simplest possible route ---
    "GET /api/health" => fn ->
      API.call(health_conn, opts)
    end,

    # --- Groups list: unauthenticated fast-path ---
    "GET /api/groups (not connected)" => fn ->
      API.call(groups_conn, opts)
    end,

    # --- Article fetch: unauthenticated fast-path ---
    "GET /api/articles/:id (not connected)" => fn ->
      API.call(article_conn, opts)
    end,

    # --- Group selection: unauthenticated fast-path ---
    "GET /api/groups/:name (not connected)" => fn ->
      API.call(group_sel_conn, opts)
    end,

    # --- Not-found route: catch-all handler ---
    "GET /api/nonexistent (404)" => fn ->
      API.call(not_found_conn, opts)
    end,

    # --- Connect: hits GenServer even if it fails ---
    "POST /api/connect (unreachable host)" => fn ->
      API.call(connect_conn, opts)
    end
  },
  time: 3,
  memory_time: 1,
  warmup: 1,
  print: [fast_warning: false],
  formatters: [
    Benchee.Formatters.Console
  ]
)
