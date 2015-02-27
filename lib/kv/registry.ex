defmodule KV.Registry do
    ## Client API

    @doc """
    Starts the registry.
    """
    def start_link(event_manager, buckets_supervisor, opts \\ []) do
        GenServer.start_link(__MODULE__, {event_manager, buckets_supervisor}, opts)
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
    
    def init({event_manager, buckets}) do
        names = HashDict.new
        refs = HashDict.new
        {:ok, %{names: names, refs: refs, events: event_manager, buckets: buckets}}
    end

    def handle_call({:lookup, name}, _from, state) do
        {:reply, HashDict.fetch(state.names, name), state}
    end
    
    def handle_call(:stop, _from, state) do
        {:stop, :normal, :ok, state} 
    end

    def handle_cast({:create, name}, state) do
        if HashDict.has_key?(state.names, name) do
            {:noreply, state}
        else
            {:ok, bucket_pid} = KV.Bucket.Supervisor.start_bucket(state.buckets)
            ref = Process.monitor(bucket_pid)
            refs2 = HashDict.put(state.refs, ref, name)
            names2 = HashDict.put(state.names, name, bucket_pid)
            GenEvent.sync_notify(state.events, {:create, name, bucket_pid})
            {:noreply, %{state | names: names2, refs: refs2}}
        end
    end

    def handle_info({:DOWN, ref, :process, pid, :normal}, state) do
        name = HashDict.get(state.refs, ref)
        refs2 = HashDict.delete(state.refs, ref)
        names2 = HashDict.delete(state.names, name)
        GenEvent.sync_notify(state.events, {:exit, name, pid})
        {:noreply, %{state | names: names2, refs: refs2}}
    end

    def handle_info(_msg, state) do
        {:noreply, state}
    end

    def terminate(_reason, _state) do
        :ok
    end
end

