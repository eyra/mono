defmodule Link.Users.User do
  @moduledoc """
  A user for the Link application.
  """

  use Ecto.Schema
  use Pow.Ecto.Schema

  schema "users" do
    pow_user_fields()

    timestamps()
  end
end
