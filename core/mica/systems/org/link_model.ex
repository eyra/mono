defmodule Systems.Org.LinkModel do
  use Ecto.Schema
  import Ecto.Changeset

  use Systems.Org.{
    Internals
  }

  schema "org_links" do
    belongs_to(:from, Node)
    belongs_to(:to, Node)

    timestamps()
  end

  @fields ~w()a

  def changeset(link, attrs) do
    link
    |> cast(attrs, @fields)
  end
end
