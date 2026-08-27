defmodule Systems.Content.PageModel do
  @moduledoc false
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  schema "content_pages" do
    field(:body, :string)
    belongs_to(:auth_node, Core.Authorization.Node)
    timestamps()
  end

  @fields ~w(body)a
  @required_fields ~w()a

  def changeset(page, attrs) do
    cast(page, attrs, @fields)
  end

  def validate(changeset) do
    validate_required(changeset, @required_fields)
  end

  def preload_graph(:down), do: preload_graph([])
end
