defmodule Core.Authentication.Actor do
  @moduledoc """
  Actor is a representation of an actor that can be authenticated.
  """

  use Ecto.Schema
  use Frameworks.Utility.Schema

  alias Ecto.Changeset

  @type t :: %__MODULE__{
          type: :system | :agent,
          name: String.t(),
          description: String.t() | nil,
          active: boolean()
        }

  schema "actor" do
    field(:type, Ecto.Enum, values: [:system, :agent])
    field(:name, :string)
    field(:description, :string)
    field(:active, :boolean, default: true)

    has_many(:tokens, Core.Authentication.ActorToken)

    timestamps()
  end

  @fields ~w(type name description active)a
  @required_fields ~w(type name)a

  def change(actor, attrs \\ %{}) do
    actor
    |> Changeset.cast(attrs, @fields)
  end

  def validate(changeset) do
    changeset
    |> Changeset.validate_required(@required_fields)
    |> Changeset.unique_constraint(:name, name: :actor_unique)
  end

  defimpl Core.Authentication.Subject do
    def name(%{type: type, name: name}) do
      case type do
        :system -> "#{name}"
        :agent -> "#{name} (Agent)"
      end
    end
  end
end
