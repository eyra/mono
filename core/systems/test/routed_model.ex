defmodule Systems.Test.RoutedModel do
  @moduledoc """
  Simple struct model for testing routed LiveViews.
  """

  defstruct [:id, :title, :children, :modal]

  @type t :: %__MODULE__{
          id: atom(),
          title: String.t(),
          children: [map()],
          modal: map() | nil
        }
end
