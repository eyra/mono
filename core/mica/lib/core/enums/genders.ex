defmodule Core.Enums.Genders do
  @moduledoc """
  Defines genders used as user feature.
  """
  use Core.Enums.Base, {:genders, [:man, :woman, :non_binary, :prefer_not_to_say]}
end
