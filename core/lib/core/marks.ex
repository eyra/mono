defmodule Core.Marks do
  @moduledoc """
  Manages instances of marks. These marks are ultimately managed by administrators belonging to certain organizations.
  For the time being a set of hardcoded marks are provided.
  """
  def instances do
    [
      %Core.Marks.Mark{id: "vu", label: "Vrije Universiteit Amsterdam"},
      %Core.Marks.Mark{id: "uva", label: "Universiteit van Amsterdam"},
      %Core.Marks.Mark{id: "uu", label: "Universiteit Utrecht"}
    ]
  end
end
