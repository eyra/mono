defmodule Systems.Instruction.Public do
  import Ecto.Query, warn: false
  alias Core.Repo
  alias Ecto.Multi

  alias Frameworks.Signal
  alias Systems.Instruction
  alias Systems.Content

  def get_tool!(id, preload \\ []) do
    from(tool in Instruction.ToolModel, preload: ^preload)
    |> Repo.get!(id)
  end

  def get_asset_by(%Content.RepositoryModel{id: id}, preload \\ []) do
    from(asset in Instruction.AssetModel,
      where: asset.repository_id == ^id,
      preload: ^preload
    )
    |> Repo.one()
  end

  def prepare_tool(attrs, auth_node \\ Core.Authorization.prepare_node()) do
    %Instruction.ToolModel{}
    |> Instruction.ToolModel.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
  end

  def prepare_asset(tool, special_key, special) do
    %Instruction.AssetModel{}
    |> Instruction.AssetModel.changeset(%{})
    |> Ecto.Changeset.put_assoc(:tool, tool)
    |> Ecto.Changeset.put_assoc(special_key, special)
  end

  def prepare_page(tool, content_page) do
    %Instruction.PageModel{}
    |> Instruction.PageModel.changeset(%{})
    |> Ecto.Changeset.put_assoc(:tool, tool)
    |> Ecto.Changeset.put_assoc(:page, content_page)
  end

  def add_repository_and_page(tool, repository, page) do
    Multi.new()
    |> Multi.insert(:content_repository, repository)
    |> Multi.insert(:instruction_asset, fn %{content_repository: content_repository} ->
      prepare_asset(tool, :repository, content_repository)
    end)
    |> Multi.insert(:content_page, page)
    |> Multi.insert(:instruction_page, fn %{content_page: content_page} ->
      prepare_page(tool, content_page)
    end)
    |> Signal.Public.multi_dispatch({:instruction_tool, :update}, %{instruction_tool: tool})
    |> Repo.transaction()
  end

  def update_repository_and_page(tool, repository, page) do
    Multi.new()
    |> Multi.update(:content_repository, repository)
    |> Multi.update(:content_page, page)
    |> Signal.Public.multi_dispatch({:instruction_tool, :update}, %{instruction_tool: tool})
    |> Repo.transaction()
  end
end
