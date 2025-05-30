defmodule Frameworks.Builder.LibraryModel do
  alias Frameworks.Builder.LibraryItemModel

  @type t :: %__MODULE__{
    items: list(LibraryItemModel.t())
  }

  defstruct [:items]
end
