defmodule KV.Supervisor do
    use Supervisor

    def start_link do
        Supervisor.start_link(__MODULE__, :ok)
    end

    @manager_name KV.EventManager
    @registry_name KV.Registry
    @bucket_sup_name KV.Bucket.Supervisor

    def init(:ok) do
        IO.puts "Starting KV.Supervisor"
        children = [
            worker(GenEvent, [[name: @manager_name]]),
            supervisor(KV.Bucket.Supervisor, [[name: @bucket_sup_name]]),
            worker(KV.Registry, [@manager_name, [name: @registry_name]])
        ]

        IO.puts "Supervising children: #{inspect children}"
        supervise(children, strategy: :one_for_one)
    end
end

