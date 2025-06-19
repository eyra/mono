defmodule Systems.Assignment.Languages do
  use Core.Enums.Base, {:assignment_languages, [:en, :es, :de, :it, :nl]}

  def default(), do: :en
end
