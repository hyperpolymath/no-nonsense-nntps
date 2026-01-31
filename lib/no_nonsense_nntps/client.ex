# SPDX-License-Identifier: PMPL-1.0-or-later
defmodule NoNonsenseNntps.Client do
  @moduledoc """
  NNTPS client GenServer for secure newsgroup protocol communication.

  Implements RFC 3977 (NNTP) over TLS (NNTPS on port 563).
  Security-first: Only supports encrypted NNTPS connections.

  ## Usage

      {:ok, pid} = NoNonsenseNntps.Client.start_link(
        host: "news.example.com",
        port: 563
      )

      {:ok, groups} = NoNonsenseNntps.Client.list_groups(pid)
      {:ok, article} = NoNonsenseNntps.Client.fetch_article(pid, "<article-id@example.com>")
  """

  use GenServer
  require Logger

  @default_port 563
  @default_timeout 30_000
  @recv_timeout 10_000

  defmodule State do
    @moduledoc false
    defstruct [
      :host,
      :port,
      :socket,
      :current_group,
      :capabilities,
      status: :disconnected
    ]
  end

  ## Client API

  @doc """
  Starts the NNTPS client GenServer.

  ## Options

    * `:host` - NNTPS server hostname (required)
    * `:port` - NNTPS server port (default: 563)
    * `:name` - GenServer name (optional)
  """
  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc """
  Connects to the NNTPS server.
  """
  def connect(pid, timeout \\ @default_timeout) do
    GenServer.call(pid, :connect, timeout)
  end

  @doc """
  Lists available newsgroups.
  """
  def list_groups(pid, timeout \\ @default_timeout) do
    GenServer.call(pid, :list_groups, timeout)
  end

  @doc """
  Selects a newsgroup and returns group info.
  """
  def select_group(pid, group_name, timeout \\ @default_timeout) do
    GenServer.call(pid, {:select_group, group_name}, timeout)
  end

  @doc """
  Fetches an article by message ID or number.
  """
  def fetch_article(pid, article_id, timeout \\ @default_timeout) do
    GenServer.call(pid, {:fetch_article, article_id}, timeout)
  end

  @doc """
  Lists articles in the current group.
  """
  def list_articles(pid, range \\ nil, timeout \\ @default_timeout) do
    GenServer.call(pid, {:list_articles, range}, timeout)
  end

  @doc """
  Disconnects from the NNTPS server.
  """
  def disconnect(pid) do
    GenServer.call(pid, :disconnect)
  end

  ## GenServer Callbacks

  @impl true
  def init(opts) do
    host = Keyword.fetch!(opts, :host)
    port = Keyword.get(opts, :port, @default_port)

    state = %State{
      host: String.to_charlist(host),
      port: port
    }

    Logger.info("NNTPS client initialized for #{host}:#{port}")
    {:ok, state}
  end

  @impl true
  def handle_call(:connect, _from, %State{status: :connected} = state) do
    {:reply, {:ok, :already_connected}, state}
  end

  def handle_call(:connect, _from, state) do
    case do_connect(state) do
      {:ok, new_state} ->
        {:reply, {:ok, :connected}, new_state}

      {:error, reason} = error ->
        Logger.error("Failed to connect: #{inspect(reason)}")
        {:reply, error, state}
    end
  end

  def handle_call(:list_groups, _from, %State{status: :connected} = state) do
    case send_command(state, "LIST ACTIVE\r\n") do
      {:ok, groups} ->
        {:reply, {:ok, parse_group_list(groups)}, state}

      {:error, reason} = error ->
        Logger.error("Failed to list groups: #{inspect(reason)}")
        {:reply, error, state}
    end
  end

  def handle_call(:list_groups, _from, state) do
    {:reply, {:error, :not_connected}, state}
  end

  def handle_call({:select_group, group_name}, _from, %State{status: :connected} = state) do
    case send_command(state, "GROUP #{group_name}\r\n") do
      {:ok, response} ->
        case parse_group_response(response) do
          {:ok, group_info} ->
            new_state = %{state | current_group: group_name}
            {:reply, {:ok, group_info}, new_state}

          {:error, _} = error ->
            {:reply, error, state}
        end

      {:error, reason} = error ->
        Logger.error("Failed to select group: #{inspect(reason)}")
        {:reply, error, state}
    end
  end

  def handle_call({:select_group, _}, _from, state) do
    {:reply, {:error, :not_connected}, state}
  end

  def handle_call({:fetch_article, article_id}, _from, %State{status: :connected} = state) do
    case send_command(state, "ARTICLE #{article_id}\r\n") do
      {:ok, article} ->
        {:reply, {:ok, parse_article(article)}, state}

      {:error, reason} = error ->
        Logger.error("Failed to fetch article: #{inspect(reason)}")
        {:reply, error, state}
    end
  end

  def handle_call({:fetch_article, _}, _from, state) do
    {:reply, {:error, :not_connected}, state}
  end

  def handle_call({:list_articles, range}, _from, %State{status: :connected} = state) do
    command =
      case range do
        nil -> "OVER\r\n"
        {first, last} -> "OVER #{first}-#{last}\r\n"
      end

    case send_command(state, command) do
      {:ok, articles} ->
        {:reply, {:ok, parse_overview(articles)}, state}

      {:error, reason} = error ->
        Logger.error("Failed to list articles: #{inspect(reason)}")
        {:reply, error, state}
    end
  end

  def handle_call({:list_articles, _}, _from, state) do
    {:reply, {:error, :not_connected}, state}
  end

  def handle_call(:disconnect, _from, %State{status: :connected, socket: socket} = state) do
    :ok = :ssl.send(socket, "QUIT\r\n")
    :ssl.close(socket)
    Logger.info("Disconnected from NNTPS server")
    {:reply, :ok, %{state | socket: nil, status: :disconnected}}
  end

  def handle_call(:disconnect, _from, state) do
    {:reply, {:error, :not_connected}, state}
  end

  ## Private Functions

  defp do_connect(%State{host: host, port: port} = state) do
    ssl_opts = [
      verify: :verify_peer,
      cacerts: :public_key.cacerts_get(),
      customize_hostname_check: [
        match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
      ],
      versions: [:"tlsv1.3", :"tlsv1.2"]
    ]

    Logger.info("Connecting to #{host}:#{port} with TLS...")

    case :ssl.connect(host, port, ssl_opts, @default_timeout) do
      {:ok, socket} ->
        case read_response(socket) do
          {:ok, greeting} ->
            Logger.info("Connected! Server greeting: #{String.trim(greeting)}")

            # Fetch capabilities
            :ok = :ssl.send(socket, "CAPABILITIES\r\n")

            case read_multiline_response(socket) do
              {:ok, caps} ->
                capabilities = parse_capabilities(caps)
                Logger.debug("Server capabilities: #{inspect(capabilities)}")

                {:ok,
                 %{state | socket: socket, status: :connected, capabilities: capabilities}}

              {:error, reason} ->
                :ssl.close(socket)
                {:error, reason}
            end

          {:error, reason} ->
            :ssl.close(socket)
            {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp send_command(%State{socket: socket}, command) do
    :ok = :ssl.send(socket, command)

    case read_response(socket) do
      {:ok, response} ->
        case parse_response_code(response) do
          {:ok, _code} ->
            # Multi-line response expected
            read_multiline_response(socket)

          {:error, code, message} ->
            {:error, {:nntps_error, code, message}}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp read_response(socket) do
    case :ssl.recv(socket, 0, @recv_timeout) do
      {:ok, data} ->
        {:ok, List.to_string(data)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp read_multiline_response(socket) do
    read_multiline_response(socket, [])
  end

  defp read_multiline_response(socket, acc) do
    case :ssl.recv(socket, 0, @recv_timeout) do
      {:ok, data} ->
        line = List.to_string(data)

        cond do
          # End of multi-line response
          String.trim(line) == "." ->
            {:ok, Enum.reverse(acc) |> Enum.join("\n")}

          # Dot-stuffed line (remove leading dot)
          String.starts_with?(line, "..") ->
            read_multiline_response(socket, [String.slice(line, 1..-1) | acc])

          true ->
            read_multiline_response(socket, [line | acc])
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_response_code(response) do
    case Integer.parse(String.trim(response)) do
      {code, rest} when code >= 200 and code < 400 ->
        {:ok, {code, String.trim(rest)}}

      {code, rest} ->
        {:error, code, String.trim(rest)}

      :error ->
        {:error, :invalid_response}
    end
  end

  defp parse_capabilities(caps_text) do
    caps_text
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> MapSet.new()
  end

  defp parse_group_list(groups_text) do
    groups_text
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(&parse_group_line/1)
    |> Enum.reject(&is_nil/1)
  end

  defp parse_group_line(line) do
    case String.split(line, " ", parts: 4) do
      [name, high, low, status] ->
        %{
          name: name,
          high: String.to_integer(high),
          low: String.to_integer(low),
          status: status
        }

      _ ->
        nil
    end
  end

  defp parse_group_response(response) do
    # Response format: "211 count first last group-name"
    case String.split(String.trim(response), " ", parts: 5) do
      ["211", count, first, last, name] ->
        {:ok,
         %{
           name: name,
           count: String.to_integer(count),
           first: String.to_integer(first),
           last: String.to_integer(last)
         }}

      _ ->
        {:error, :invalid_group_response}
    end
  end

  defp parse_article(article_text) do
    case String.split(article_text, "\n\n", parts: 2) do
      [headers, body] ->
        %{
          headers: parse_headers(headers),
          body: body
        }

      [text] ->
        %{
          headers: %{},
          body: text
        }
    end
  end

  defp parse_headers(headers_text) do
    headers_text
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(&parse_header_line/1)
    |> Enum.reject(&is_nil/1)
    |> Map.new()
  end

  defp parse_header_line(line) do
    case String.split(line, ":", parts: 2) do
      [key, value] ->
        {String.downcase(key), String.trim(value)}

      _ ->
        nil
    end
  end

  defp parse_overview(overview_text) do
    overview_text
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(&parse_overview_line/1)
    |> Enum.reject(&is_nil/1)
  end

  defp parse_overview_line(line) do
    # OVER format: number\tsubject\tfrom\tdate\tmessage-id\treferences\tbytes\tlines
    case String.split(line, "\t") do
      [num, subject, from, date, msg_id | _] ->
        %{
          number: String.to_integer(num),
          subject: subject,
          from: from,
          date: date,
          message_id: msg_id
        }

      _ ->
        nil
    end
  end
end
