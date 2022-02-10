defmodule Systems.Lab.SearchSubjectModel do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field(:query, :string)
  end

  @fields ~w(query)a

  def changeset(model, :init, params) do
    model
    |> cast(params, @fields)
  end

  def changeset(model, :submit, params) do
    model
    |> cast(params, @fields)
    |> validate_required(@fields)
  end
end
