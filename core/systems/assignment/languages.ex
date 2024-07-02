defmodule Systems.Assignment.Languages do
  use Core.Enums.Base, {:assignment_languages, [:en, :de, :nl]}

  def default(), do: :en
end
