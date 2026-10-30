defmodule Systems.Assignment.Languages do
  use Mica.Enums.Base, {:assignment_languages, [:en, :es, :de, :it, :nl, :ro, :lt]}

  def default(), do: :en
end
