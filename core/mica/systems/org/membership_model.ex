defmodule Systems.Org.MembershipModel do
  @moduledoc """
  Records who added a member to an organisation and when, and once the member is
  removed, who removed them and when. The `:member` role on the organisation's
  auth node is the membership itself; this record is its history. A member added
  again gets a new record.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Systems.Account.User
  alias Systems.Org

  schema "org_memberships" do
    belongs_to(:org, Org.NodeModel)
    belongs_to(:user, User)
    belongs_to(:added_by, User)
    field(:removed_at, :utc_datetime)
    belongs_to(:removed_by, User)

    timestamps()
  end

  def add_changeset(%Org.NodeModel{id: org_id}, %User{id: user_id}, added_by) do
    %__MODULE__{}
    |> change(%{org_id: org_id, user_id: user_id, added_by_id: id(added_by)})
    |> unique_constraint([:org_id, :user_id], name: :org_memberships_current_index)
  end

  def remove_changeset(%__MODULE__{} = membership, removed_by) do
    change(membership, %{
      removed_at: DateTime.utc_now() |> DateTime.truncate(:second),
      removed_by_id: id(removed_by)
    })
  end

  defp id(%User{id: id}), do: id
  defp id(nil), do: nil
end
