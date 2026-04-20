defmodule Systems.Workflow.Config do
  @type library :: Frameworks.Builder.LibraryModel.t()
  @type item :: atom()

  @type t :: %__MODULE__{
          singleton?: boolean(),
          library: library(),
          initial_items: list(item()),
          group_enabled?: boolean() | nil
        }

  defstruct [:singleton?, :library, :initial_items, group_enabled?: nil]
end
