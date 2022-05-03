defmodule Systems.Crew.RejectCategories do
  @moduledoc """
    Defines languages used as user feature.
  """
  use Core.Enums.Base, {:reject_catagories, [:attention_checks_failed, :not_completed, :other]}

  def icon(:attention_checks_failed), do: "🚦"
  def icon(:not_completed), do: "🚧"
  def icon(_), do: "🚫"
end
