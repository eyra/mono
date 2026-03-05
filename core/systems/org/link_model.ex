defmodule Systems.Org.LinkModel do
  @moduledoc false
  use Ecto.Schema
  use Systems.Org.Internals

  import Ecto.Changeset

  schema "org_links" do
    belongs_to(:from, Node)
    belongs_to(:to, Node)

    timestamps()
  end

  @fields ~w()a

  def changeset(link, attrs) do
    cast(link, attrs, @fields)
  end
end
