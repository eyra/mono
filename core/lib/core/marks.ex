defmodule Core.Marks do
  @moduledoc """
  Manages instances of marks. These marks are ultimately managed by administrators belonging to certain organizations.
  For the time being a set of hardcoded marks are provided.
  """
  alias Core.Marks.Mark

  def instances do
    [
      %Mark{id: "vu", label: "Vrije Universiteit Amsterdam"},
      %Mark{id: "uva", label: "Universiteit van Amsterdam"},
      %Mark{id: "uu", label: "Universiteit Utrecht"}
    ]
  end
end
