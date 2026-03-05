defmodule Systems.Citizen.Public do
  @moduledoc false
  use Core, :public

  alias Systems.Pool

  @pool_director_key "citizen"

  def list_pools(preload \\ []), do: Pool.Public.list_by_director(@pool_director_key, preload)
end
