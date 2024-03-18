defmodule Systems.Assignment.Templates do
  @moduledoc """
    Defines different templates used by Systems.Assignment.Assembly to initialize specials.
  """
  use Core.Enums.Base,
      {:templates, [:online, :lab, :data_donation, :graphite]}
end
