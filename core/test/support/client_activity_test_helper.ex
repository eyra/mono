defmodule Systems.Admin.ClientActivityTestHelper do
  @moduledoc """
  Builds project assignments with explicit fund and project owners for the
  Client activity tests.
  """
  alias Core.Factories

  @doc """
  Inserts a project with one assignment item.

  Options:
  - `:fund_owners` / `:project_owners`: list of `{user, inserted_at}` owner rows
  - `:status`: assignment status (default `:concept`)
  - `:inserted_at`: assignment creation time (default now)
  - `:name`: project item name
  """
  def insert_project_assignment(opts) do
    project =
      Factories.insert!(:project, %{
        name: "Project",
        auth_node: auth_node_with_owners(Keyword.get(opts, :project_owners, []))
      })

    fund =
      Factories.build(:fund, %{
        name: Ecto.UUID.generate(),
        auth_node: auth_node_with_owners(Keyword.get(opts, :fund_owners, []))
      })

    assignment =
      Factories.insert!(:assignment, %{
        status: Keyword.get(opts, :status, :concept),
        inserted_at: Keyword.get(opts, :inserted_at, now()),
        auth_node: Factories.build(:auth_node, %{parent_id: project.auth_node_id}),
        fund: fund
      })

    Factories.insert!(:project_item, %{
      name: Keyword.get(opts, :name, "Assignment #{assignment.id}"),
      project_path: [],
      node_id: project.root_id,
      assignment: assignment
    })

    assignment
  end

  def owner(user, inserted_at \\ nil), do: {user, inserted_at || now()}

  def now, do: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

  defp auth_node_with_owners(owners) do
    role_assignments =
      Enum.map(owners, fn {user, inserted_at} ->
        Factories.build(:role_assignment, %{
          role: :owner,
          principal_id: user.id,
          inserted_at: inserted_at,
          updated_at: inserted_at
        })
      end)

    Factories.build(:auth_node, %{role_assignments: role_assignments})
  end
end
