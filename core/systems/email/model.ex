defmodule Systems.Email.Model do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  alias Systems.Email.Model

  embedded_schema do
    @derive Jason.Encoder
    field(:from, :string)
    field(:to, {:array, :string})
    field(:title, :string)
    field(:byline, :string)
    field(:message, :string)
  end

  @fields ~w(from to title byline message)a

  def changeset(:init, %Model{} = email, attrs) do
    cast(email, attrs, @fields)
  end

  def changeset(:validate, %Model{} = email, attrs) do
    email
    |> cast(attrs, @fields)
    |> validate_required(@fields)
  end
end
