defmodule Core.Enums.Themes do
  @moduledoc """
  Defines themes used to categorize studies or tools wihin studies.
  """
  use Core.Enums.Base,
      {:themes, [:health, :history, :politics, :art, :language, :technology, :society]}
end
