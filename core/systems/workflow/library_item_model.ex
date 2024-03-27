defmodule Systems.Workflow.LibraryItemModel do
  @type t :: %__MODULE__{
          special: atom(),
          tool: atom(),
          title: binary(),
          description: binary() | nil
        }

  defstruct [:special, :tool, :title, :description]
end
