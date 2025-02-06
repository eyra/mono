defmodule Systems.Project.NodePageEmptyDataView do
  use CoreWeb, :live_component

  alias Systems.Project

  def update(%{node: node} = _assigns, socket) do
    {
      :ok,
      socket
      |> assign(:node, node)
      |> assign(:expire_button, compose_child(:create_storage_button))
    }
  end

  def handle_event("trigger_create_storage", _value, %{assigns: %{node: node}} = socket) do
    project = Project.Public.get_by_root(node)

    case Project.Assembly.attach_storage_to_project(project) do
      {:ok, _changes} ->
        {:noreply,
         put_flash(
           socket,
           :info,
           dgettext("eyra-project", "node.data.empty.create-storage-success")
         )}

      {:error, _reason} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           dgettext("eyra-project", "node.data.empty.create-storage-failed")
         )}
    end
  end

  def compose_child(:create_storage_button) do
    %{
      action: %{
        type: :send,
        event: "trigger_create_storage"
      },
      face: %{
        type: :primary,
        label: dgettext("eyra-project", "node.data.empty.create-storage")
      }
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content >
        <div class="flex flex-col justify-center items-center">
          <Margin.y id={:page_top} />
          <div class="flex flex-row items-center gap-3 mb-6">
            <Text.title2>{dgettext("eyra-project", "node.data.empty.title")}</Text.title2>
          </div>
          <Text.body_large>
            {dgettext("eyra-project", "node.data.empty.description")}
          </Text.body_large>
          <div class="my-6">
            <Button.dynamic {@expire_button} />
          </div>
        </div>
      </Area.content>
    </div>
    """
  end
end
