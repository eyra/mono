defmodule Systems.Test.ModalModel do
  @moduledoc """
  Model for testing modal toolbar button functionality.
  """

  defstruct [:id, :title, :button_configs]

  @type t :: %__MODULE__{
          id: atom(),
          title: String.t(),
          button_configs: [map()]
        }
end
