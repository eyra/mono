defmodule Frameworks.Builder.LibraryItemModel do
  @moduledoc """
  An item a builder can add. `required?` is copied onto what is added: only required
  items count when deciding whether a participant finished their tasks.
  """

  @type t :: %__MODULE__{
          id: atom() | binary(),
          type: atom() | tuple(),
          title: binary(),
          description: binary() | nil,
          tags: list(binary()) | nil,
          required?: boolean()
        }

  defstruct [:id, :type, :title, :description, :tags, required?: true]
end
