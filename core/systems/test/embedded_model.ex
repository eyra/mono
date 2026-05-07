defmodule Systems.Test.EmbeddedModel do
  @moduledoc """
  Simple struct model for testing embedded LiveViews.
  """

  defstruct [:id, :title, :items]

  @type t :: %__MODULE__{
          id: atom(),
          title: String.t(),
          items: [integer()]
        }
end
