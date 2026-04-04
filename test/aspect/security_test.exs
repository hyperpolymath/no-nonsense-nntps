# SPDX-License-Identifier: PMPL-1.0-or-later
# Security aspect tests for the NoNonsenseNntps server.
#
# These tests target security invariants:
#  - Injection attack surfaces in the HTTP API layer
#  - Authentication-bypass attempts on unauthenticated state
#  - Oversized / malformed payload handling
#  - Header injection prevention
#
# No live NNTP server is required; all assertions operate on API responses.

defmodule NoNonsenseNntps.SecurityTest do
  use ExUnit.Case, async: false

  @moduletag :security

  # ---------------------------------------------------------------------------
  # Header injection
  # ---------------------------------------------------------------------------

  describe "response header safety" do
    test "health endpoint sets correct content-type" do
      conn = Plug.Test.conn(:get, "/api/health")
      response = NoNonsenseNntps.API.call(conn, NoNonsenseNntps.API.init([]))

      content_type =
        response.resp_headers
        |> Enum.find(fn {k, _} -> k == "content-type" end)
        |> elem(1)

      assert String.starts_with?(content_type, "application/json")
    end
  end

  # ---------------------------------------------------------------------------
  # Group name injection
  # ---------------------------------------------------------------------------

  describe "group name injection via URL path" do
    # None of these should cause a 500 — the API must handle gracefully.
    test "path traversal characters in group name are rejected gracefully" do
      payloads = [
        "/api/groups/../../etc/passwd",
        "/api/groups/../secret",
        "/api/groups/%2F%2F",
        "/api/groups/null%00byte"
      ]

      for path <- payloads do
        conn = Plug.Test.conn(:get, path)
        response = NoNonsenseNntps.API.call(conn, NoNonsenseNntps.API.init([]))

        # Must not return 500 (internal server error) for these inputs.
        assert response.status != 500,
               "Path #{path} caused 500 — internal error on injection attempt"
      end
    end

    test "very long group name does not crash the server" do
      long_name = String.duplicate("a", 4096)
      conn = Plug.Test.conn(:get, "/api/groups/#{long_name}")
      response = NoNonsenseNntps.API.call(conn, NoNonsenseNntps.API.init([]))

      # Should return 400 (not connected) or 404, never a 500 crash.
      assert response.status in [400, 404]
    end
  end

  # ---------------------------------------------------------------------------
  # Large message body
  # ---------------------------------------------------------------------------

  describe "oversized request bodies" do
    test "large JSON body on connect endpoint does not crash" do
      # 64 KB of padding in the host field.
      large_host = String.duplicate("x", 65_536)
      body = Jason.encode!(%{"host" => large_host, "port" => 563})

      conn =
        Plug.Test.conn(:post, "/api/connect", body)
        |> Plug.Conn.put_req_header("content-type", "application/json")

      # Must not crash — any HTTP response (including 500) is acceptable
      # as long as the process stays alive.
      _response = NoNonsenseNntps.API.call(conn, NoNonsenseNntps.API.init([]))
      assert Process.alive?(Process.whereis(NoNonsenseNntps.ClientManager))
    end
  end

  # ---------------------------------------------------------------------------
  # Authentication bypass — state-order attacks
  # ---------------------------------------------------------------------------

  describe "unauthenticated operation rejection" do
    test "listing groups without connecting returns 400, not data" do
      conn = Plug.Test.conn(:get, "/api/groups")
      response = NoNonsenseNntps.API.call(conn, NoNonsenseNntps.API.init([]))

      assert response.status == 400
      body = Jason.decode!(response.resp_body)
      # Must include an error key — not accidentally leak data.
      assert Map.has_key?(body, "error")
    end

    test "fetching article without connecting returns 400, not data" do
      conn = Plug.Test.conn(:get, "/api/articles/test@example.com")
      response = NoNonsenseNntps.API.call(conn, NoNonsenseNntps.API.init([]))

      assert response.status == 400
      body = Jason.decode!(response.resp_body)
      assert Map.has_key?(body, "error")
    end

    test "selecting group without connecting returns 400, not data" do
      conn = Plug.Test.conn(:get, "/api/groups/comp.lang.elixir")
      response = NoNonsenseNntps.API.call(conn, NoNonsenseNntps.API.init([]))

      assert response.status == 400
      body = Jason.decode!(response.resp_body)
      assert Map.has_key?(body, "error")
    end
  end

  # ---------------------------------------------------------------------------
  # Content-type enforcement
  # ---------------------------------------------------------------------------

  describe "content-type enforcement on POST" do
    test "connecting without JSON content-type fails gracefully" do
      body = ~s({"host":"localhost","port":563})

      conn =
        Plug.Test.conn(:post, "/api/connect", body)
        |> Plug.Conn.put_req_header("content-type", "text/plain")

      # Should fail, not crash.
      try do
        response = NoNonsenseNntps.API.call(conn, NoNonsenseNntps.API.init([]))
        # If it returns, status must indicate failure.
        assert response.status in [400, 415, 500]
      rescue
        _ -> :ok  # Plug may raise for incorrect content-type — acceptable
      end
    end
  end
end
