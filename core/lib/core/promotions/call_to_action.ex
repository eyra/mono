defmodule Core.Promotions.CallToAction.Target do
  @moduledoc """
  """
  defstruct [:type, :value]

  @type t() :: %__MODULE__{
    type: :event | :navigation,
    value: String.t()
  }
end

defmodule Core.Promotions.CallToAction do
  @moduledoc """
  """
  defstruct [:label, :target]

  @type t() :: %__MODULE__{
    label: String.t(),
    target: %Core.Promotions.CallToAction.Target{}
  }
end
