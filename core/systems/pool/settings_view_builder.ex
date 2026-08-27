defmodule Systems.Pool.SettingsViewBuilder do
  @moduledoc false
  alias Systems.Pool

  def view_model(%Pool.Model{} = pool, _assigns) do
    %{changeset: Pool.Model.change(pool, %{})}
  end
end
