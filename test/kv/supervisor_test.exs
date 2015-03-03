defmodule KV.SupervisorTest do
	use ExUnit.Case, async: true
	
	test "all buckets die if registry dies" do
		reg = KV.Registry
		KV.Registry.create(reg, "shopping")
		{:ok, shopping_bucket} = KV.Registry.lookup(reg, "shopping")
	
		Process.exit(reg, :shutdown)
		assert_receive {:exit, "shopping", ^shopping_bucket}
	end
end
