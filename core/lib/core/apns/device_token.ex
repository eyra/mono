defmodule Core.APNS.DeviceToken do
  use Ecto.Schema
  import Ecto.Changeset
  alias Systems.Account.User

  schema "apns_device_tokens" do
    field(:device_token, :string)
    belongs_to(:user, User)

    timestamps()
  end

  @doc false
  def changeset(push_token, attrs) do
    push_token
    |> cast(attrs, [:device_token])
    |> put_assoc(:user, attrs.user)
    |> validate_required([:device_token, :user])
  end
end
