defmodule Systems.Org.Internals do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      alias Org.LinkModel, as: Link
      alias Org.NodeModel, as: Node
      alias Org.Types
      alias Org.UserAssociation
      alias Systems.Org

      require Types
    end
  end
end
