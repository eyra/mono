defmodule Systems.Account.UserProfileModel do
  @moduledoc """
  This schema contains profile related data for members.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Systems.Account.User

  schema "user_profiles" do
    field(:fullname, :string)
    field(:title, :string)
    field(:photo_url, :string)
    belongs_to(:user, User)
    timestamps()
  end

  @type t() :: %__MODULE__{
          __meta__: Ecto.Schema.Metadata.t(),
          id: integer() | nil,
          fullname: String.t() | nil,
          title: String.t() | nil,
          photo_url: String.t() | nil,
          user_id: integer() | nil,
          user: User.t() | Ecto.Association.NotLoaded.t() | nil,
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  @fields ~w(fullname title photo_url)a

  @doc false
  def changeset(profile, attrs) do
    profile
    |> cast(attrs, @fields)
  end
end
