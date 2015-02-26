defmodule KV.Registry do
    ## Client API

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

    @doc """
    Stops the server.
    """
    def stop(server) do
        GenServer.call(server, :stop)
    end


    ## Server callbacks
    
    def init(:ok) do
        names = HashDict.new
        refs = HashDict.new
        {:ok, {names, refs}}
    end

    def handle_call({:lookup, name}, _from, {names, _} = state) do
        {:reply, HashDict.fetch(names, name), state}
    end
    
    def handle_call(:stop, _from, state) do
        {:stop, :normal, :ok, state} 
    end

    def handle_cast({:create, name}, {names, refs} = state) do
        if HashDict.has_key?(names, name) do
            {:noreply, state}
        else
            {:ok, bucket_pid} = KV.Bucket.start_link()
            ref = Process.monitor(bucket_pid)
            refs2 = HashDict.put(refs, ref, name)
            names2 = HashDict.put(names, name, bucket_pid)
            {:noreply, {names2, refs2}}
        end
    end

    def handle_info({:DOWN, ref, :process, _pid, :normal}, {names, refs}) do
        name = HashDict.get(refs, ref)
        refs2 = HashDict.delete(refs, ref)
        names2 = HashDict.delete(names, name)
        {:noreply, {names2, refs2}}
    end

    def terminate(_reason, _state) do
        :ok
    end
end

