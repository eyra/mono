defmodule Core.Enums.Genders do
  @moduledoc """
  Defines genders used as user feature.
  """
  use Core.Enums.Base, {:genders, [:man, :woman, :x]}
end
