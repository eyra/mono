defmodule Link.UserIdentities.UserIdentity do
  @moduledoc """
  An oauth user identity for the Link application.
  """

  use Ecto.Schema
  use PowAssent.Ecto.UserIdentities.Schema, user: Link.Users.User

  schema "user_identities" do
    pow_assent_user_identity_fields()

    timestamps()
  end
end
