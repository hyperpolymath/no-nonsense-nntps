# SPDX-License-Identifier: PMPL-1.0-or-later
defmodule NoNonsenseNntps.API do
  @moduledoc """
  HTTP API for no-nonsense-nntps.

  Provides REST endpoints for the ReScript frontend to interact with the NNTPS client.

  ## Endpoints

    * `GET /api/health` - Health check
    * `POST /api/connect` - Connect to NNTPS server
    * `GET /api/groups` - List newsgroups
    * `GET /api/groups/:name` - Select group and get info
    * `GET /api/groups/:name/articles` - List articles in group
    * `GET /api/articles/:id` - Fetch article by message ID

  """

  use Plug.Router
  require Logger

  plug(CORSPlug,
    origin: ["http://localhost:8000", "http://localhost:3000"],
    methods: ["GET", "POST", "OPTIONS"]
  )

  plug(:match)
  plug(Plug.Parsers, parsers: [:json], json_decoder: Jason)
  plug(:dispatch)

  ## Routes

  get "/api/health" do
    send_json(conn, 200, %{status: "ok", service: "no-nonsense-nntps"})
  end

  post "/api/connect" do
    %{"host" => host} = conn.body_params
    port = Map.get(conn.body_params, "port", 563)

    case NoNonsenseNntps.ClientManager.connect(host, port) do
      {:ok, :connected} ->
        send_json(conn, 200, %{status: "connected", host: host, port: port})

      {:error, reason} ->
        send_json(conn, 500, %{error: "connection_failed", reason: inspect(reason)})
    end
  end

  get "/api/groups" do
    case NoNonsenseNntps.ClientManager.list_groups() do
      {:ok, groups} ->
        send_json(conn, 200, %{groups: groups})

      {:error, :not_connected} ->
        send_json(conn, 400, %{error: "not_connected", message: "Connect to server first"})

      {:error, reason} ->
        send_json(conn, 500, %{error: "fetch_failed", reason: inspect(reason)})
    end
  end

  get "/api/groups/:name" do
    group_name = conn.path_params["name"]

    case NoNonsenseNntps.ClientManager.select_group(group_name) do
      {:ok, group_info} ->
        send_json(conn, 200, group_info)

      {:error, :not_connected} ->
        send_json(conn, 400, %{error: "not_connected"})

      {:error, reason} ->
        send_json(conn, 500, %{error: "group_select_failed", reason: inspect(reason)})
    end
  end

  get "/api/groups/:name/articles" do
    group_name = conn.path_params["name"]
    query_params = Plug.Conn.fetch_query_params(conn).query_params

    range =
      case {query_params["first"], query_params["last"]} do
        {first, last} when is_binary(first) and is_binary(last) ->
          {String.to_integer(first), String.to_integer(last)}

        _ ->
          nil
      end

    # First select the group
    with {:ok, _} <- NoNonsenseNntps.ClientManager.select_group(group_name),
         {:ok, articles} <- NoNonsenseNntps.ClientManager.list_articles(range) do
      send_json(conn, 200, %{articles: articles})
    else
      {:error, :not_connected} ->
        send_json(conn, 400, %{error: "not_connected"})

      {:error, reason} ->
        send_json(conn, 500, %{error: "fetch_failed", reason: inspect(reason)})
    end
  end

  get "/api/articles/:id" do
    article_id = conn.path_params["id"]

    case NoNonsenseNntps.ClientManager.fetch_article(article_id) do
      {:ok, article} ->
        send_json(conn, 200, article)

      {:error, :not_connected} ->
        send_json(conn, 400, %{error: "not_connected"})

      {:error, reason} ->
        send_json(conn, 500, %{error: "fetch_failed", reason: inspect(reason)})
    end
  end

  match _ do
    send_json(conn, 404, %{error: "not_found"})
  end

  ## Helpers

  defp send_json(conn, status, data) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(data))
  end
end
