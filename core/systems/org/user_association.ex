defmodule Systems.Org.UserAssociation do
  @moduledoc false
  use Ecto.Schema
  use Systems.Org.Internals

  import Ecto.Changeset

  alias Systems.Account.User

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
