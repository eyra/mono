defmodule Core.Studies.Author do
  @moduledoc """
  The schema for a study author.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Core.Studies.Study
  alias Core.Accounts
  alias Core.Accounts.User

  @primary_key false
  schema "authors" do
    field(:fullname, :string)
    field(:displayname, :string)

    belongs_to(:study, Study)
    belongs_to(:user, User)

    timestamps()
  end

  @required_fields ~w(fullname displayname)a

  def from_user(%User{} = user) do
    profile =
      user
      |> Accounts.get_profile()

    fullname =
      case profile.fullname do
        nil -> user.email
        _ -> profile.fullname
      end

    displayname =
      case user.displayname do
        nil -> user.email |> String.split("@") |> List.first()
        _ -> user.displayname
      end

    %{
      fullname: fullname,
      displayname: displayname
    }
  end

  def changeset(params) do
    %Core.Studies.Author{}
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end
end
