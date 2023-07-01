defmodule Systems.DataDonation.Public do
  @moduledoc """

  A data donation allows a researcher to ask participants to submit data. This
  data is submitted in the form of a file that is stored on the participants
  device.

  Tools are provided that allow for execution of filtering code on the device
  of the participant. This ensures that only the data that is needed for the
  study is shared with the researcher.
  """

  import Ecto.Query, warn: false
  alias Core.Repo

  alias Ecto.Multi
  alias Core.Authorization

  alias Systems.{
    DataDonation
  }

  def list do
    Repo.all(DataDonation.ToolModel)
  end

  def list_tasks(tool_id, preload \\ []) do
    from(task in DataDonation.TaskModel,
      where: task.tool_id == ^tool_id,
      order_by: {:asc, :position},
      preload: ^preload
    )
    |> Repo.all()
  end

  def get_tool!(id, preload \\ []) do
    from(a in DataDonation.ToolModel, preload: ^preload)
    |> Repo.get!(id)
  end

  def get_task!(id, preload \\ []) do
    from(task in DataDonation.TaskModel, preload: ^preload)
    |> Repo.get!(id)
  end

  def get_task(tool_id, position, preload \\ []) do
    from(task in DataDonation.TaskModel,
      where: task.tool_id == ^tool_id,
      where: task.position == ^position,
      preload: ^preload
    )
    |> Repo.one()
  end

  def get_document_task!(id, preload \\ []) do
    from(task in DataDonation.DocumentTaskModel, preload: ^preload)
    |> Repo.get!(id)
  end

  def create(
        %{subject_count: _, director: _} = attrs,
        %Authorization.Node{} = auth_node
      ) do
    attrs = Map.put(attrs, :status, :concept)

    %DataDonation.ToolModel{}
    |> DataDonation.ToolModel.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
  end

  def add_task(tool, task_type) when is_binary(task_type) do
    add_task(tool, String.to_existing_atom(task_type))
  end

  def add_task(%DataDonation.ToolModel{} = tool, task_type) do
    Multi.new()
    |> Multi.run(:position, fn _, _ ->
      {:ok, task_count(tool)}
    end)
    |> Multi.insert(:task_special, create_task_special(task_type))
    |> Multi.insert(:task, fn %{position: position, task_special: task_special} ->
      create_task(tool, position, task_type, task_special)
    end)
    |> Repo.transaction()
  end

  def task_count(%DataDonation.ToolModel{id: tool_id}) do
    from(task in DataDonation.TaskModel,
      where: task.tool_id == ^tool_id,
      select: count(task.id)
    )
    |> Repo.one()
  end

  def create_task(%DataDonation.ToolModel{} = tool, position, task_type, special) do
    %DataDonation.TaskModel{}
    |> DataDonation.TaskModel.changeset(%{position: position})
    |> Ecto.Changeset.put_assoc(:tool, tool)
    |> Ecto.Changeset.put_assoc(task_type, special)
  end

  def create_task_special(:survey_task) do
    %DataDonation.SurveyTaskModel{}
    |> DataDonation.SurveyTaskModel.changeset(%{})
  end

  def create_task_special(:request_task) do
    %DataDonation.DocumentTaskModel{}
    |> DataDonation.DocumentTaskModel.changeset(%{})
  end

  def create_task_special(:download_task) do
    %DataDonation.DocumentTaskModel{}
    |> DataDonation.DocumentTaskModel.changeset(%{})
  end

  def create_task_special(:donate_task) do
    %DataDonation.DonateTaskModel{}
    |> DataDonation.DonateTaskModel.changeset(%{})
  end

  def update(changeset) do
    Multi.new()
    |> Repo.multi_update(:data_donation_tool, changeset)
    |> Repo.transaction()
  end

  def delete(%DataDonation.ToolModel{} = tool) do
    Multi.new()
    |> Multi.delete(:data_donation_tool, tool)
    |> Repo.transaction()
  end

  def delete(%DataDonation.TaskModel{tool_id: tool_id} = task) do
    Multi.new()
    |> Multi.delete(:task, task)
    |> Multi.run(:tasks, fn _, _ ->
      {:ok, list_tasks(tool_id)}
    end)
    |> Multi.run(:order_and_update, fn _, %{tasks: tasks} ->
      {:ok, rearrange(tasks)}
    end)
    |> Repo.transaction()
  end

  def update_position(%DataDonation.TaskModel{tool_id: tool_id, position: old}, new)
      when old == new,
      do: {:ok, %{tasks: list_tasks(tool_id)}}

  def update_position(%DataDonation.TaskModel{id: id, tool_id: tool_id, position: old}, new) do
    Multi.new()
    |> Multi.run(:tasks, fn _, _ ->
      {:ok, list_tasks(tool_id)}
    end)
    |> Multi.run(:validate_old_position, fn _, %{tasks: tasks} ->
      validate_old_position(tasks, id, old)
    end)
    |> Multi.run(:validate_new_position, fn _, %{tasks: tasks} ->
      validate_new_position(tasks, new)
    end)
    |> Multi.run(:order_and_update, fn _, %{tasks: tasks} ->
      {:ok, rearrange(tasks, old, new)}
    end)
    |> Repo.transaction()
  end

  def validate_old_position(tasks, id, pos) do
    validate_old_position(tasks, id, pos, Enum.count(tasks))
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

  def validate_old_position([], _, _, _), do: {:error, :task_not_found}

  def validate_new_position(tasks, pos) do
    if pos >= 0 and pos < Enum.count(tasks) do
      {:ok, true}
    else
      {:error, :out_of_bounds}
    end
  end

  def rearrange(tasks, old, new) do
    {task, tasks} = List.pop_at(tasks, old)

    tasks
    |> List.insert_at(new, task)
    |> rearrange()
  end

  def rearrange(tasks) do
    tasks
    |> Enum.with_index()
    |> Enum.map(&prepare_update_position/1)
    |> Enum.map(&Repo.update/1)
  end

  def prepare_update_position({%DataDonation.TaskModel{} = task, index}) do
    DataDonation.TaskModel.changeset(task, %{position: index})
  end

  def copy(%DataDonation.ToolModel{} = tool, auth_node) do
    %DataDonation.ToolModel{}
    |> DataDonation.ToolModel.changeset(Map.from_struct(tool))
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
    |> Repo.insert!()
  end
end

defimpl Core.Persister, for: Systems.DataDonation.ToolModel do
  def save(_tool, changeset) do
    case Systems.DataDonation.Public.update(changeset) do
      {:ok, %{data_donation_tool: tool}} -> {:ok, tool}
      _ -> {:error, changeset}
    end
  end
end
