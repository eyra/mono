defmodule Systems.Pool.DetailPageBuilder do
  def view_model(pool, _assigns) do
    %{
      pool: pool,
      tabs: []
    }
  end
end
