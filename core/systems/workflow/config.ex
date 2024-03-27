defmodule Systems.Workflow.Config do
  @type library :: Systems.Workflow.LibraryModel.t()
  @type item :: atom()

  @type t :: %__MODULE__{
          type: atom(),
          library: library(),
          initial_items: list(item())
        }

  defstruct [:type, :library, :initial_items]
end
