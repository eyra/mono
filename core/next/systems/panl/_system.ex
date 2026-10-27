defmodule Next.Panl.System do
  @moduledoc """
  The PaNL flags. Mica's Account, Assignment, Home, Pool and Project systems
  still read them; they are declared here so that no PaNL name is added to Mica,
  and move with that code in plan step code-instance.
  """
  use Core.System

  def feature_flags, do: [:panl, :panl_post_launch]
end
