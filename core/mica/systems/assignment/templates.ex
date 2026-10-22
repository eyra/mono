defmodule Systems.Assignment.Templates do
  @moduledoc """
    Defines different templates used by Systems.Assignment.Assembly to initialize specials.
  """
  use Core.Enums.Base,
      {:templates, [:data_donation, :benchmark_challenge, :questionnaire, :paper_screening]}
end
