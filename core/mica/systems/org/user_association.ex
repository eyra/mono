defmodule Systems.Org.UserAssociation do
  use Ecto.Schema
  import Ecto.Changeset

  alias Systems.Account.User

  use Systems.Org.{
    Internals
  }

  schema "org_users" do
    belongs_to(:org, Node)
    belongs_to(:user, User)

    timestamps()
  end

  def changeset(schema, %Node{} = node, %User{} = user) do
    schema
    |> change(%{})
    |> Ecto.Changeset.put_assoc(:org, node)
    |> Ecto.Changeset.put_assoc(:user, user)
  end
end
