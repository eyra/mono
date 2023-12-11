defmodule Systems.Assignment.PageRefModel do
  use Ecto.Schema
  import Ecto.Changeset

  alias Systems.Assignment
  alias Systems.Content

  @fields ~w(key)a

  @primary_key false
  schema "assignment_page_refs" do
    field(:key, Ecto.Atom)
    belongs_to(:assignment, Assignment.Model)
    belongs_to(:page, Content.PageModel)

    timestamps()
  end

  def changeset(page_ref, params) do
    page_ref
    |> cast(params, @fields)
  end
end
