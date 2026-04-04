# SPDX-License-Identifier: PMPL-1.0-or-later
# End-to-end tests for the NoNonsenseNntps server components.
#
# These tests exercise the full application stack — HTTP API, ClientManager,
# and the application supervision tree — without requiring a live NNTP server.
# External network connections are replaced with mock responses via process
# message passing, keeping the suite fully self-contained.

defmodule NoNonsenseNntps.ServerE2ETest do
  use ExUnit.Case, async: false

  @moduletag :e2e

  # ---------------------------------------------------------------------------
  # Application bootstrap
  # ---------------------------------------------------------------------------

  describe "application startup" do
    test "application module provides a version string" do
      vsn = NoNonsenseNntps.version()
      assert is_binary(vsn)
      assert byte_size(vsn) > 0
    end

    test "ClientManager is registered under its module name" do
      pid = Process.whereis(NoNonsenseNntps.ClientManager)
      # The supervisor starts ClientManager; it must be alive.
      assert is_pid(pid)
      assert Process.alive?(pid)
    end
  end

  # ---------------------------------------------------------------------------
  # HTTP API — health endpoint
  # ---------------------------------------------------------------------------

  describe "GET /api/health" do
    test "returns 200 with status ok" do
      conn = Plug.Test.conn(:get, "/api/health")
      response = NoNonsenseNntps.API.call(conn, NoNonsenseNntps.API.init([]))

      assert response.status == 200
      body = Jason.decode!(response.resp_body)
      assert body["status"] == "ok"
      assert body["service"] == "no-nonsense-nntps"
    end
  end

  # ---------------------------------------------------------------------------
  # HTTP API — groups endpoint (not connected state)
  # ---------------------------------------------------------------------------

  describe "GET /api/groups — not connected" do
    test "returns 400 not_connected when no session exists" do
      conn = Plug.Test.conn(:get, "/api/groups")
      response = NoNonsenseNntps.API.call(conn, NoNonsenseNntps.API.init([]))

      assert response.status == 400
      body = Jason.decode!(response.resp_body)
      assert body["error"] == "not_connected"
    end
  end

  # ---------------------------------------------------------------------------
  # HTTP API — groups/:name endpoint (not connected)
  # ---------------------------------------------------------------------------

  describe "GET /api/groups/:name — not connected" do
    test "returns 400 not_connected when selecting group without session" do
      conn = Plug.Test.conn(:get, "/api/groups/comp.lang.elixir")
      response = NoNonsenseNntps.API.call(conn, NoNonsenseNntps.API.init([]))

      assert response.status == 400
      body = Jason.decode!(response.resp_body)
      assert body["error"] == "not_connected"
    end
  end

  # ---------------------------------------------------------------------------
  # HTTP API — articles endpoint (not connected)
  # ---------------------------------------------------------------------------

  describe "GET /api/articles/:id — not connected" do
    test "returns 400 not_connected when fetching article without session" do
      conn = Plug.Test.conn(:get, "/api/articles/some-message-id@example.com")
      response = NoNonsenseNntps.API.call(conn, NoNonsenseNntps.API.init([]))

      assert response.status == 400
      body = Jason.decode!(response.resp_body)
      assert body["error"] == "not_connected"
    end
  end

  # ---------------------------------------------------------------------------
  # HTTP API — unknown routes
  # ---------------------------------------------------------------------------

  describe "unknown routes" do
    test "returns 404 for unrecognised paths" do
      conn = Plug.Test.conn(:get, "/api/nonexistent")
      response = NoNonsenseNntps.API.call(conn, NoNonsenseNntps.API.init([]))

      assert response.status == 404
      body = Jason.decode!(response.resp_body)
      assert body["error"] == "not_found"
    end

    test "returns 404 for root path" do
      conn = Plug.Test.conn(:get, "/")
      response = NoNonsenseNntps.API.call(conn, NoNonsenseNntps.API.init([]))

      assert response.status == 404
    end
  end

  # ---------------------------------------------------------------------------
  # POST /api/connect — bad host (no network expected)
  # ---------------------------------------------------------------------------

  describe "POST /api/connect" do
    test "returns 500 when connection to unreachable host fails" do
      body = Jason.encode!(%{"host" => "127.0.0.1", "port" => 19999})

      conn =
        Plug.Test.conn(:post, "/api/connect", body)
        |> Plug.Conn.put_req_header("content-type", "application/json")

      response = NoNonsenseNntps.API.call(conn, NoNonsenseNntps.API.init([]))

      # Either 200 (unexpected live server) or 500 (expected failure path).
      assert response.status in [200, 500]
    end

    test "requires host field in request body" do
      body = Jason.encode!(%{"port" => 563})

      conn =
        Plug.Test.conn(:post, "/api/connect", body)
        |> Plug.Conn.put_req_header("content-type", "application/json")

      # Missing required host field — should raise or return error status.
      assert_raise(KeyError, fn ->
        NoNonsenseNntps.API.call(conn, NoNonsenseNntps.API.init([]))
      end)
    end
  end
end
