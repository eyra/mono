defmodule Systems.Rate.Quota do
  import Frameworks.Utility.ConfigHelpers

  @type t :: %__MODULE__{
          service: String.t(),
          limit: integer,
          unit: :byte | :call,
          window: :day | :hour | :minute | :second,
          scope: :local | :global
        }

  @enforce_keys [:service, :limit, :unit, :window, :scope]
  defstruct [:service, :limit, :unit, :window, :scope]

  def init(quota) do
    %__MODULE__{
      service: get!(:string, quota, :service),
      limit: get!(:integer, quota, :limit),
      unit: get!(:atom, quota, :unit, [:byte, :call]),
      window: get!(:atom, quota, :window, [:day, :hour, :minute, :second]),
      scope: get!(:atom, quota, :scope, [:local, :global])
    }
  end
end

"""
[
  {\"service\": \"storage_export\", \"limit\": 10, \"unit\": \"call\", \"window\": \"minute\", \"scope\": \"local\"},
  {\"service\": \"storage_export\", \"limit\": 1000000, \"unit\": \"byte\", \"window\": \"day\", \"scope\": \"local\"},
  {\"service\": \"storage_export\", \"limit\": 100000000, \"unit\": \"byte\", \"window\": \"day\", \"scope\": \"global\"}
]
"""
