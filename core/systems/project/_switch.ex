defmodule Systems.Project.Switch do
  use Frameworks.Signal.Handler

  alias Frameworks.Signal

  alias Systems.{
    Project,
    DataDonation
  }

  @impl true
  def dispatch(:data_donation_tool, %{changeset: changeset}) do
    tool_id = Ecto.Changeset.get_field(changeset, :id)
    update_pages(tool_id)
  end

  @impl true
  def dispatch(:data_donation_task, %{changeset: changeset}) do
    task_id = Ecto.Changeset.get_field(changeset, :id)
    task = DataDonation.Public.get_task!(task_id)
    update_pages(task)
  end

  @impl true
  def dispatch(:data_donation_document_task, %{changeset: changeset}) do
    special_id = Ecto.Changeset.get_field(changeset, :id)

    task =
      DataDonation.Public.get_task_by_special!([:request_task_id, :download_task_id], special_id)

    update_pages(task)
  end

  @impl true
  def dispatch(:data_donation_questionnaire_task, %{changeset: changeset}) do
    special_id = Ecto.Changeset.get_field(changeset, :id)
    task = DataDonation.Public.get_task_by_special!(:questionnaire_task_id, special_id)
    update_pages(task)
  end

  @impl true
  def dispatch(:data_donation_donate_task, %{changeset: changeset}) do
    special_id = Ecto.Changeset.get_field(changeset, :id)
    task = DataDonation.Public.get_task_by_special!(:donate_task_id, special_id)
    update_pages(task)
  end

  @impl true
  def dispatch(:data_donation_tasks, %{tool_id: tool_id}) do
    update_pages(tool_id)
  end

  defp update_pages(%DataDonation.TaskModel{tool_id: tool_id}) do
    update_pages(tool_id)
  end

  defp update_pages(tool_id) when is_integer(tool_id) do
    Project.Public.get_tool_refs_by_tool!(:data_donation_tool_id, tool_id, [:item])
    |> Enum.each(&update_pages/1)
  end

  defp update_pages(%Project.ToolRefModel{item: item}) do
    update_pages(item)
  end

  defp update_pages(%Project.ItemModel{id: item_id}) do
    [Project.ItemContentPage]
    |> Enum.each(&update_page(&1, item_id))
  end

  defp update_page(page, item_id) do
    Signal.Public.dispatch!(%{page: page}, %{id: item_id, model: %{id: item_id}})
  end
end
