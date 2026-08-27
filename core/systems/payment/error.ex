defmodule Systems.Payment.Error do
  @moduledoc false
  @type t :: %__MODULE__{
          code: atom(),
          message: String.t(),
          details: map()
        }

  defstruct [:code, :message, details: %{}]
end
