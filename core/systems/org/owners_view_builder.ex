defmodule Systems.Org.OwnersViewBuilder do
  @moduledoc false
  alias Systems.Org

  def view_model(node, _assigns) do
    owners = Org.Public.list_owners(node)

    %{
      owners: owners
    }
  end
end
