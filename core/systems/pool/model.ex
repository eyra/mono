defmodule Systems.Pool.Model do
  @moduledoc """
  The pool schema.
  """
  use Ecto.Schema

  alias Core.Accounts.User

  alias Systems.{
    Promotion
  }

  schema "pools" do
    field(:name, :string)

    many_to_many(:participants, User, join_through: :pool_participants)
    many_to_many(:promotions, Promotion.Model, join_through: :pool_submissions)

    timestamps()
  end
end
