# SPDX-License-Identifier: PMPL-1.0-or-later
defmodule NoNonsenseNntps.ClientManager do
  @moduledoc """
  Manages the singleton NNTPS client instance.

  Provides a simple interface for the API to interact with the NNTPS client
  without managing PIDs directly.
  """

  use GenServer
  require Logger

  @client_name :nntps_client

  ## Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Connect to an NNTPS server.
  """
  def connect(host, port \\ 563) do
    GenServer.call(__MODULE__, {:connect, host, port})
  end

  @doc """
  List available newsgroups.
  """
  def list_groups do
    GenServer.call(__MODULE__, :list_groups, 60_000)
  end

  @doc """
  Select a newsgroup.
  """
  def select_group(group_name) do
    GenServer.call(__MODULE__, {:select_group, group_name})
  end

  @doc """
  List articles in the current group.
  """
  def list_articles(range \\ nil) do
    GenServer.call(__MODULE__, {:list_articles, range}, 60_000)
  end

  @doc """
  Fetch an article.
  """
  def fetch_article(article_id) do
    GenServer.call(__MODULE__, {:fetch_article, article_id})
  end

  @doc """
  Disconnect from the server.
  """
  def disconnect do
    GenServer.call(__MODULE__, :disconnect)
  end

  ## GenServer Callbacks

  @impl true
  def init(_opts) do
    {:ok, %{client_pid: nil, host: nil, port: nil}}
  end

  @impl true
  def handle_call({:connect, host, port}, _from, state) do
    # Stop existing client if any
    if state.client_pid do
      NoNonsenseNntps.Client.disconnect(state.client_pid)
    end

    # Start new client
    case NoNonsenseNntps.Client.start_link(host: host, port: port, name: @client_name) do
      {:ok, pid} ->
        case NoNonsenseNntps.Client.connect(pid) do
          {:ok, :connected} ->
            Logger.info("Connected to #{host}:#{port}")
            {:reply, {:ok, :connected}, %{state | client_pid: pid, host: host, port: port}}

          {:ok, :already_connected} ->
            {:reply, {:ok, :connected}, %{state | client_pid: pid, host: host, port: port}}

          {:error, reason} = error ->
            Logger.error("Connection failed: #{inspect(reason)}")
            {:reply, error, state}
        end

      {:error, {:already_started, pid}} ->
        # Client already exists, try to connect
        case NoNonsenseNntps.Client.connect(pid) do
          {:ok, status} ->
            {:reply, {:ok, status}, %{state | client_pid: pid, host: host, port: port}}

          error ->
            {:reply, error, state}
        end

      {:error, reason} = error ->
        Logger.error("Failed to start client: #{inspect(reason)}")
        {:reply, error, state}
    end
  end

  def handle_call(_request, _from, %{client_pid: nil} = state) do
    {:reply, {:error, :not_connected}, state}
  end

  def handle_call(:list_groups, _from, %{client_pid: pid} = state) do
    result = NoNonsenseNntps.Client.list_groups(pid, 60_000)
    {:reply, result, state}
  end

  def handle_call({:select_group, group_name}, _from, %{client_pid: pid} = state) do
    result = NoNonsenseNntps.Client.select_group(pid, group_name)
    {:reply, result, state}
  end

  def handle_call({:list_articles, range}, _from, %{client_pid: pid} = state) do
    result = NoNonsenseNntps.Client.list_articles(pid, range, 60_000)
    {:reply, result, state}
  end

  def handle_call({:fetch_article, article_id}, _from, %{client_pid: pid} = state) do
    result = NoNonsenseNntps.Client.fetch_article(pid, article_id)
    {:reply, result, state}
  end

  def handle_call(:disconnect, _from, %{client_pid: pid} = state) when not is_nil(pid) do
    result = NoNonsenseNntps.Client.disconnect(pid)
    {:reply, result, %{state | client_pid: nil}}
  end

  def handle_call(:disconnect, _from, state) do
    {:reply, {:error, :not_connected}, state}
  end
end
