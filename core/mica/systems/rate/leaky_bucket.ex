defmodule Systems.Rate.LeakyBucket do
  @type t :: %__MODULE__{
          level: number,
          capacity: number,
          drop_rate: number,
          updated_at: DateTime.t()
        }

  @enforce_keys [:level, :capacity, :drop_rate, :updated_at]
  defstruct [:level, :capacity, :drop_rate, :updated_at]

  def update(%__MODULE__{} = bucket, level, updated_at) do
    bucket
    |> Map.put(:level, level)
    |> Map.put(:updated_at, updated_at)
  end

  def level(%__MODULE__{} = bucket, date, new_drops) do
    level(bucket, date) + new_drops
  end

  def level(%__MODULE__{level: level, drop_rate: drop_rate, updated_at: updated_at}, date) do
    time_past = DateTime.diff(date, updated_at, :millisecond)
    max(0, level - time_past * drop_rate)
  end
end
