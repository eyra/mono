defmodule Systems.Rate.Bucket do
  @type t :: %__MODULE__{
    drops: integer,
    updated_at: DateTime.t()
  }

  @enforce_keys [:drops, :updated_at]
  defstruct [:drops, :updated_at]

  @spec update(__MODULE__.t, integer, DateTime.t) :: __MODULE__.t
  def update(%Bucket{} = bucket, drops, updated_at) do
    bucket
    |> Map.put(:drops, drops + new_drops)
    |> Map.put(:updated_at, updated_at)
  end
end
