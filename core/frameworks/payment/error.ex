defmodule Frameworks.Payment.Error do
  @type t :: %__MODULE__{
          code: atom(),
          message: String.t(),
          details: map()
        }

  defstruct [:code, :message, details: %{}]
end
