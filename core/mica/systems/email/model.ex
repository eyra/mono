defmodule Systems.Email.Model do
  @moduledoc """
  A notification email, as `Systems.Email.Public.deliver_later!/1` queues it.

  `subject` and `html_message` are optional. Without a subject the email has
  the default one; without `html_message` the HTML part is made from the
  plain-text `message`.
  """
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    @derive Jason.Encoder
    field(:from, :string)
    field(:to, {:array, :string})
    field(:subject, :string)
    field(:title, :string)
    field(:byline, :string)
    field(:message, :string)
    field(:html_message, :string)
  end

  @fields ~w(from to title byline message)a

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
