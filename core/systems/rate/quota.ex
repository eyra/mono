defmodule Systems.Rate.Quota do
  @type t :: %__MODULE__{
          service: String.t(),
          limit: integer,
          unit: :byte | :call,
          window: :day | :hour | :minute | :second,
          scope: :local | :global
        }

  @enforce_keys [:service, :limit, :unit, :window, :scope]
  defstruct [:service, :limit, :unit, :window, :scope]

  def init(quota) when is_list(quota) do
    %__MODULE__{
      service: Keyword.get(quota, :service),
      limit: Keyword.get(quota, :limit),
      unit: Keyword.get(quota, :unit),
      window: Keyword.get(quota, :window),
      scope: Keyword.get(quota, :scope)
    }
  end
end
