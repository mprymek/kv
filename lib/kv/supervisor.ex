defmodule KV.BucketAndRegistrySupervisor do
    use Supervisor

    @manager_name KV.EventManager
    @registry_name KV.Registry
    @bucket_sup_name KV.Bucket.Supervisor
    
    def start_link(opts \\ []) do
        Supervisor.start_link(__MODULE__, :ok, opts)
    end
    
    def init(:ok) do
        children = [
            supervisor(KV.Bucket.Supervisor, [[name: @bucket_sup_name]]),
            worker(KV.Registry, [@manager_name, [name: @registry_name]])
        ]
        
        supervise(children, strategy: :one_for_all)
    end
end

defmodule KV.Bucket.Supervisor do
    use Supervisor

    def start_link(opts \\ []) do
        Supervisor.start_link(__MODULE__, :ok, opts)
    end

    def start_bucket(supervisor) do
        Supervisor.start_child(supervisor, [])
    end

    def init(:ok) do
        children = [
            worker(KV.Bucket, [], restart: :temporary)
        ]

        supervise(children, strategy: :simple_one_for_one)
    end
end

defmodule KV.Supervisor do
    use Supervisor

    def start_link do
        Supervisor.start_link(__MODULE__, :ok)
    end

    @manager_name KV.EventManager
    @registry_name KV.Registry
    @bucket_sup_name KV.Bucket.Supervisor
    @bucket_and_reg_sup_name KV.BucketAndRegistrySupervisor

    def init(:ok) do
        IO.puts "Starting KV.Supervisor"
        children = [
            worker(GenEvent, [[name: @manager_name]]),
#            supervisor(KV.BucketAndRegistrySupervisor, [[name: @bucket_and_reg_sup_name]])
            supervisor(KV.Bucket.Supervisor, [[name: @bucket_sup_name]]),
            worker(KV.Registry, [@manager_name, [name: @registry_name]])
        ]
        IO.puts "Supervising children: #{inspect children}"
        supervise(children, strategy: :one_for_one)
    end
    
    def get_buckets_registry(sup) do
        [_mgr, _buckets_sup, reg] = Supervisor.which_children(sup)
        reg
    end
end

