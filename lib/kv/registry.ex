defmodule KV.Registry do
    @doc """
    Starts the registry.
    """
    def start_link(opts \\ []) do
        GenServer.start_link(__MODULE__, :ok, opts)
    end

    @doc """
    Looks up the bucket pid for `name` stored in `server`.

    Returns `{:ok, pid}` if the bucket exists, `:error` otherwise.
    """
    def lookup(server, name) do
        GenServer.call(server, {:lookup, name})
    end

    @doc """
    Ensures there is a bucket associated with the given `name` in
    `server.`
    """
    def create(server, name) do
        GenServer.cast(server, {:create, name})
    end

    ## Server callbacks
    def init(:ok) do
        names = HashDict.new
        {:ok, names}
    end

    def handle_call({:lookup, name}, _from, names) do
        {:reply, HashDict.fetch(names, name), names}
    end

    def handle_cast({:create, name}, names) do
        if HashDict.has_key?(names, name) do
            {:noreply, names}
        else
            {:ok, bucket} = KV.Bucket.start_link()
            {:noreply, HashDict.put(names, name, bucket)}
        end
    end
end

