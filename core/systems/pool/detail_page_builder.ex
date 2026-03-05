defmodule Systems.Pool.DetailPageBuilder do
  @moduledoc false
  def view_model(pool, _assigns) do
    %{
      pool: pool,
      tabs: []
    }
  end
end
