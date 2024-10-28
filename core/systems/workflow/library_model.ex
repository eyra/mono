defmodule Systems.Workflow.LibraryModel do
  @type t :: %__MODULE__{
          items: list(Systems.Workflow.LibraryItemModel.t())
        }

  defstruct [:items]
end
