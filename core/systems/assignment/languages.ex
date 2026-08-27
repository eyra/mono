defmodule Systems.Assignment.Languages do
  @moduledoc false
  use Core.Enums.Base, {:assignment_languages, [:en, :es, :de, :it, :nl, :ro, :lt]}

  def default, do: :en
end
