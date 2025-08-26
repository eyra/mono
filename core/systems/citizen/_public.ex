defmodule Systems.Citizen.Public do
  use Core, :public
  @pool_director_key "citizen"

  alias Systems.{
    Pool
  }

  def list_pools(preload \\ []), do: Pool.Public.list_by_director(@pool_director_key, preload)
end
