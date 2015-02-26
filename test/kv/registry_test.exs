defmodule KV.RegistryTest do
    use ExUnit.Case, async: true

    setup do
        {:ok, registry} = KV.Registry.start_link
        {:ok, registry: registry}
    end

    test "spawns buckets", %{registry: registry} do
        assert KV.Registry.lookup(registry, "tasks") === :error

        KV.Registry.create(registry, "tasks")
        assert {:ok, bucket} = KV.Registry.lookup(registry, "tasks")

        task = "learn Elixir"
        KV.Bucket.put(bucket, task, :in_progress)
        assert KV.Bucket.get(bucket, task) === :in_progress
    end
end

