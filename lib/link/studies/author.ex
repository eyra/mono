defmodule Link.Studies.Author do
  @moduledoc """
  The schema for a study author.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Link.Studies.Study
  alias Link.Users
  alias Link.Users.User

  @primary_key false
  schema "authors" do
    field :fullname, :string
    field :displayname, :string

    belongs_to :study, Study
    belongs_to :user, User

    timestamps()
  end

  @required_fields ~w(fullname displayname)a

  def from_user(%User{} = user) do
    profile =
      user
      |> Users.get_profile()

    fullname =
      case profile.fullname do
        nil -> user.email
        _ -> profile.fullname
      end

    displayname =
      case profile.displayname do
        nil -> user.email |> String.split("@") |> List.first()
        _ -> profile.displayname
      end

    %{
      fullname: fullname,
      displayname: displayname
    }
  end

  def changeset(params) do
    %Link.Studies.Author{}
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end
end
