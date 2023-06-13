defmodule Systems.Benchmark.Public do
  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias Ecto.Changeset
  alias Core.Repo
  alias Core.Authorization

  alias Systems.{
    Benchmark
  }

  def get_tool!(id, preload \\ []) do
    from(b in Benchmark.ToolModel, preload: ^preload)
    |> Repo.get!(id)
  end

  def set_tool_status(%Benchmark.ToolModel{} = tool, status) do
    tool
    |> Benchmark.ToolModel.changeset(%{status: status})
    |> Repo.update!()
  end

  def set_tool_status(id, status) do
    get_tool!(id)
    |> set_tool_status(status)
  end

  def get_spot!(id, preload \\ []) do
    from(s in Benchmark.SpotModel, preload: ^preload)
    |> Repo.get!(id)
  end

  def create(
        %{title: _, director: _} = attrs,
        %Authorization.Node{} = auth_node
      ) do
    attrs = Map.put(attrs, :status, :concept)

    %Benchmark.ToolModel{}
    |> Benchmark.ToolModel.changeset(attrs)
    |> Changeset.put_assoc(:auth_node, auth_node)
  end

  def create_spot(tool_id, %{displayname: displayname} = user) do
    tool = Benchmark.Public.get_tool!(tool_id)

    Multi.new()
    |> Multi.insert(:auth_node, Authorization.make_node())
    |> Multi.insert(:spot, fn %{auth_node: auth_node} ->
      %Benchmark.SpotModel{}
      |> Benchmark.SpotModel.changeset(%{name: displayname})
      |> Changeset.put_assoc(:auth_node, auth_node)
      |> Changeset.put_assoc(:tool, tool)
    end)
    |> Multi.run(:assign_role, fn _, %{spot: spot} ->
      {:ok, Authorization.assign_role(user, spot, :owner)}
    end)
    |> Repo.transaction()
  end

  def create_spot!(tool_id, user) do
    case create_spot(tool_id, user) do
      {:ok, %{spot: spot}} -> spot
      _ -> nil
    end
  end

  def create_submission(%Changeset{} = changeset) do
    changeset
    |> Repo.insert(
      conflict_target: [:id],
      on_conflict: :replace_all
    )
  end

  def list_spots_for_tool(user, tool_id, preload \\ []) do
    node_ids =
      Authorization.query_node_ids(
        role: :owner,
        principal: user
      )

    from(spot in Benchmark.SpotModel,
      where: spot.tool_id == ^tool_id,
      where: spot.auth_node_id in subquery(node_ids),
      preload: ^preload
    )
    |> Repo.all()
  end

  def list_spots(user, preload \\ []) do
    node_ids =
      Authorization.query_node_ids(
        role: :owner,
        principal: user
      )

    from(spot in Benchmark.SpotModel,
      where: spot.auth_node_id in subquery(node_ids),
      preload: ^preload
    )
    |> Repo.all()
  end

  def delete(%Benchmark.SubmissionModel{} = submission) do
    Repo.delete(submission)
  end
end
