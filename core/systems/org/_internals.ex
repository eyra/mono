defmodule Systems.Org.Internals do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      alias Systems.Org
      alias Systems.Org.LinkModel, as: Link
      alias Systems.Org.NodeModel, as: Node
      alias Systems.Org.UserAssociation
    end
  end
end
