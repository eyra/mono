defmodule Systems.Assignment.ConsentPeriodModel do
  @moduledoc """
  A span of time in which consent was on for an assignment. `ended_at` is nil
  while consent is still on.
  """
  use Ecto.Schema

  embedded_schema do
    field(:started_at, :naive_datetime)
    field(:ended_at, :naive_datetime)
  end

  def during?(%__MODULE__{started_at: started_at, ended_at: ended_at}, %NaiveDateTime{} = moment) do
    NaiveDateTime.compare(moment, started_at) != :lt and
      (is_nil(ended_at) or NaiveDateTime.compare(moment, ended_at) == :lt)
  end
end
