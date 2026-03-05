defmodule Systems.Workflow.Config do
  @moduledoc false
  @type library :: Frameworks.Builder.LibraryModel.t()
  @type item :: atom()

  @type t :: %__MODULE__{
          singleton?: boolean(),
          library: library(),
          initial_items: list(item())
        }

  defstruct [:singleton?, :library, :initial_items]
end
