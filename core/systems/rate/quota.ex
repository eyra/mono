defmodule Systems.Rate.Quota do
  @type t :: %__MODULE__{
    service: String.t(),
    rate_limit: integer,
    window: :seconds | :minutes | :hours,
    scope: :local | :global
  }

  @enforce_keys [:service, :rate_limit, :window, :scope]
  defstruct [:service, :rate_limit, :window, :scope]
end
