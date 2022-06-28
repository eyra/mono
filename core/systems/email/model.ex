defmodule Systems.Email.Model do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field(:from, :string)
    field(:to, {:array, :string})
    field(:subject, :string)
    field(:message, :string)
  end

  @fields ~w(from to subject message)a

  def changeset(:init, %Systems.Email.Model{} = email, attrs) do
    email
    |> cast(attrs, @fields)
  end

  def changeset(:validate, %Systems.Email.Model{} = email, attrs) do
    email
    |> cast(attrs, @fields)
    |> validate_required(@fields)
  end
end
