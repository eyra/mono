defmodule Systems.Crew.RejectModel do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field(:category, :string)
    field(:message, :string)
  end

  @fields ~w(category message)a

  def changeset(model, :init, params) do
    model
    |> cast(params, [:category, :message])
  end

  def changeset(model, :submit, params) do
    model
    |> cast(params, @fields)
    |> validate_required(@fields)
  end

end
