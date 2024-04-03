defmodule Systems.Workflow.LibraryModel do
  @type t :: %__MODULE__{
          render?: boolean(),
          items: list(Systems.Workflow.LibraryItemModel.t())
        }

  defstruct [:render?, :items]
end
