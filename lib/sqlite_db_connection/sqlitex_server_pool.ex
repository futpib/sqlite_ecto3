defmodule Sqlite.DbConnection.SqlitexServerPool do
  use GenServer

  @initial_state %{
    db_path_to_pid: %{},
    pid_to_db_path: %{},
    pid_to_reference_count: %{},
  }

  def start_link(_) do
    GenServer.start_link(__MODULE__, @initial_state, name: __MODULE__)
  end

  # Client

  def acquire_server(opts) do
    db_path = Keyword.fetch!(opts, :database)
    db_timeout = Keyword.get(opts, :db_timeout, 5000)

    GenServer.call(__MODULE__, {:acquire_server, db_path, db_timeout})
  end

  def release_server(pid) do
    GenServer.call(__MODULE__, {:release_server, pid})
  end

  # Server (callbacks)

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:acquire_server, db_path, db_timeout}, _from, state) do
    case Map.get(state[:db_path_to_pid], db_path) do
      nil ->
        {:ok, pid} = Sqlitex.Server.start_link(db_path, db_timeout: db_timeout)
        :ok = Sqlitex.Server.exec(pid, "PRAGMA foreign_keys = ON")
        {:ok, [[foreign_keys: 1]]} = Sqlitex.Server.query(pid, "PRAGMA foreign_keys")

        state =
          state
          |> update_in([:db_path_to_pid, db_path], fn _ -> pid end)
          |> update_in([:pid_to_db_path, pid], fn _ -> db_path end)
          |> update_in([:pid_to_reference_count, pid], fn
            nil -> 1
            n -> n + 1
          end)

        {:reply, pid, state}

      pid ->
        state =
          state
          |> update_in([:pid_to_reference_count, pid], fn
            nil -> 1
            n -> n + 1
          end)

        {:reply, pid, state}
    end
  end

  @impl true
  def handle_call({:release_server, pid}, _from, state) do
    state = update_in(state, [:pid_to_reference_count, pid], fn n -> n - 1 end)

    state = if get_in(state, [:pid_to_reference_count, pid]) === 0 do
      GenServer.stop(pid)

      db_path = Map.fetch!(state[:pid_to_db_path], pid)

      state
      |> update_in([:pid_to_db_path, pid], fn ^db_path -> nil end)
      |> update_in([:db_path_to_pid, db_path], fn ^pid -> nil end)
    else
      state
    end

    {:reply, :ok, state}
  end
end
