defmodule Frameworks.Builder.LibraryItemModel do
  @type t :: %__MODULE__{
    id: atom() | binary(),
    type: atom() | tuple(),
    title: binary(),
    description: binary() | nil,
    tags: list(binary()) | nil
  }

  defstruct [:id, :type, :title, :description, :tags]
end
