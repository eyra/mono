defmodule Systems.Workflow.Public do
  import Ecto.Query, warn: false
  import Systems.Workflow.Queries

  alias Ecto.Multi
  alias Core.Repo

  alias Frameworks.Signal

  alias Systems.Workflow
  alias Systems.Document
  alias Systems.Alliance
  alias Systems.Feldspar
  alias Systems.Lab
  alias Systems.Graphite
  alias Systems.Instruction
  alias Systems.Zircon

  def list_items(workflow, preload \\ [])
  def list_items(%Workflow.Model{id: id}, preload), do: list_items(id, preload)

  def list_items(workflow_id, preload) do
    from(item in Workflow.ItemModel,
      where: item.workflow_id == ^workflow_id,
      order_by: {:asc, :position},
      preload: ^preload
    )
    |> Repo.all()
  end

  def get!(id, preload \\ []) do
    from(item in Workflow.Model, preload: ^preload)
    |> Repo.get!(id)
  end

  def get_item!(id, preload \\ []) do
    from(item in Workflow.ItemModel, preload: ^preload)
    |> Repo.get!(id)
  end

  def get_item_by_tool(%{id: id} = tool, preload \\ []) do
    field = Workflow.ToolRefModel.tool_id_field(tool)
    get_item_by_tool!(field, id, preload)
  end

  def get_item_by_tool_ref(tool_ref, preload \\ [])

  def get_item_by_tool_ref(%Workflow.ToolRefModel{id: id}, preload) do
    get_item_by_tool_ref(id, preload)
  end

  def get_item_by_tool_ref(tool_ref_id, preload) do
    from(item in Workflow.ItemModel,
      where: item.tool_ref_id == ^tool_ref_id,
      preload: ^preload
    )
    |> Repo.one()
  end

  def get_item_by_tool!(field, tool_id, preload \\ [])

  def get_item_by_tool!(field, tool_id, preload) when is_atom(field) do
    get_item_by_tool!([field], tool_id, preload)
  end

  def get_item_by_tool!([hd | tl] = _keys, tool_id, preload) when is_integer(tool_id) do
    query =
      from(item in Workflow.ItemModel,
        inner_join: tool_ref in Workflow.ToolRefModel,
        on: tool_ref.id == item.tool_ref_id,
        where: field(tool_ref, ^hd) == ^tool_id,
        preload: ^preload
      )

    Enum.reduce(tl, query, fn key, query ->
      query |> or_where([tool_ref], field(tool_ref, ^key) == ^tool_id)
    end)
    |> Repo.one!()
  end

  def add_item(workflow_id, %{} = item, director) when is_integer(workflow_id) do
    get!(workflow_id)
    |> add_item(item, director)
  end

  def add_item(
        %Workflow.Model{auth_node: %Ecto.Association.NotLoaded{}} = workflow,
        item,
        director
      ) do
    add_item(Repo.preload(workflow, :auth_node), item, director)
  end

  def add_item(
        %Workflow.Model{auth_node: workflow_auth_node} = workflow,
        %{special: special, tool: tool_type} = _item,
        director
      )
      when is_atom(director) do
    Multi.new()
    |> Multi.run(:position, fn _, _ ->
      {:ok, item_count(workflow)}
    end)
    |> Multi.insert(:tool, prepare_tool(tool_type, %{director: director}, workflow_auth_node))
    |> Multi.insert(:workflow_item, fn %{position: position, tool: tool} ->
      tool_ref = prepare_tool_ref(special, tool_type, tool)
      prepare_item(workflow, position, tool_ref)
    end)
    |> Signal.Public.multi_dispatch({:workflow_item, :added})
    |> Repo.transaction()
  end

  def list_tools(%Workflow.Model{} = workflow, special) do
    preload = Workflow.ItemModel.preload_graph(:down)

    item_query(workflow, special)
    |> Repo.all()
    |> Repo.preload(preload)
    |> Enum.map(& &1.tool_ref)
    |> Enum.map(&Workflow.ToolRefModel.tool/1)
  end

  def item_count(%Workflow.Model{id: workflow_id}) do
    from(item in Workflow.ItemModel,
      where: item.workflow_id == ^workflow_id,
      select: count(item.id)
    )
    |> Repo.one()
  end

  def prepare_item(%Workflow.Model{} = workflow, position, tool_ref) do
    %Workflow.ItemModel{}
    |> Workflow.ItemModel.changeset(%{position: position})
    |> Ecto.Changeset.put_assoc(:workflow, workflow)
    |> Ecto.Changeset.put_assoc(:tool_ref, tool_ref)
  end

  def prepare_tool_ref(special, tool_type, tool) do
    %Workflow.ToolRefModel{}
    |> Workflow.ToolRefModel.changeset(%{special: special})
    |> Ecto.Changeset.put_assoc(tool_type, tool)
  end

  def prepare_tool(:zircon_screening_tool, %{} = attrs, auth_node),
    do: Zircon.Public.prepare_screening_tool(attrs, auth_node)

  def prepare_tool(:alliance_tool, %{} = attrs, auth_node),
    do: Alliance.Public.prepare_tool(attrs, auth_node)

  def prepare_tool(:document_tool, %{} = attrs, auth_node),
    do: Document.Public.prepare_tool(attrs, auth_node)

  def prepare_tool(:feldspar_tool, %{} = attrs, auth_node),
    do: Feldspar.Public.prepare_tool(attrs, auth_node)

  def prepare_tool(:lab_tool, %{} = attrs, auth_node),
    do: Lab.Public.prepare_tool(attrs, auth_node)

  def prepare_tool(:graphite_tool, %{} = attrs, auth_node),
    do: Graphite.Public.prepare_tool(attrs, auth_node)

  def prepare_tool(:instruction_tool, %{} = attrs, auth_node),
    do: Instruction.Public.prepare_tool(attrs, auth_node)

  def delete(%Workflow.ItemModel{workflow_id: workflow_id} = item) do
    Multi.new()
    |> Multi.delete(:workflow_item, item)
    |> Multi.run(:items, fn _, _ ->
      {:ok, list_items(workflow_id)}
    end)
    |> Multi.run(:order_and_update, fn _, %{items: items} ->
      {:ok, rearrange(items)}
    end)
    |> Signal.Public.multi_dispatch({:workflow_item, :deleted})
    |> Repo.transaction()
  end

  def update_position(%Workflow.ItemModel{workflow_id: workflow_id, position: old}, new)
      when old == new,
      do: {:ok, %{items: list_items(workflow_id)}}

  def update_position(%Workflow.ItemModel{id: id, workflow_id: workflow_id, position: old}, new) do
    Multi.new()
    |> Multi.run(:items, fn _, _ ->
      {:ok, list_items(workflow_id)}
    end)
    |> Multi.run(:validate_old_position, fn _, %{items: items} ->
      validate_old_position(items, id, old)
    end)
    |> Multi.run(:validate_new_position, fn _, %{items: items} ->
      validate_new_position(items, new)
    end)
    |> Multi.run(:order_and_update, fn _, %{items: items} ->
      {:ok, rearrange(items, old, new)}
    end)
    |> Signal.Public.multi_dispatch({:workflow, :rearranged}, %{id: id, workflow_id: workflow_id})
    |> Repo.transaction()
  end

  def validate_old_position(items, id, pos) do
    validate_old_position(items, id, pos, Enum.count(items))
  end

  def validate_old_position([%{id: id_, position: pos_} | _], id, pos, count)
      when id == id_ and pos == pos_ do
    if pos >= 0 and pos < count do
      {:ok, true}
    else
      {:error, :out_of_bounds}
    end
  end

  def validate_old_position([%{id: id_} | _], id, _, _) when id == id_, do: {:error, :out_of_sync}

  def validate_old_position([_ | tl], id, pos, count),
    do: validate_old_position(tl, id, pos, count)

  def validate_old_position([], _, _, _), do: {:error, :item_not_found}

  def validate_new_position(items, pos) do
    if pos >= 0 and pos < Enum.count(items) do
      {:ok, true}
    else
      {:error, :out_of_bounds}
    end
  end

  def rearrange(items, old, new) do
    {item, items} = List.pop_at(items, old)

    items
    |> List.insert_at(new, item)
    |> rearrange()
  end

  def rearrange(items) do
    items
    |> Enum.with_index()
    |> Enum.map(&prepare_update_position/1)
    |> Enum.map(&Repo.update/1)
  end

  def prepare_update_position({%Workflow.ItemModel{} = item, index}) do
    Workflow.ItemModel.changeset(item, %{position: index})
  end
end

defimpl Core.Persister, for: Systems.Workflow.Model do
  def save(_task, changeset) do
    case Frameworks.Utility.EctoHelper.update_and_dispatch(changeset, :workflow) do
      {:ok, %{workflow: workflow}} -> {:ok, workflow}
      _ -> {:error, changeset}
    end
  end
end

defimpl Core.Persister, for: Systems.Workflow.ItemModel do
  def save(_task, changeset) do
    case Frameworks.Utility.EctoHelper.update_and_dispatch(changeset, :workflow_item) do
      {:ok, %{workflow_item: workflow_item}} -> {:ok, workflow_item}
      _ -> {:error, changeset}
    end
  end
end
