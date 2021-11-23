defmodule Systems.Crew.RejectCategories do
  @moduledoc """
    Defines languages used as user feature.
  """
  use Core.Enums.Base, {:reject_catagories, [:attention_checks_failed, :not_completed, :other]}
end
