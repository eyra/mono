defmodule Systems.Manual.Builder.ToolForm do
  use CoreWeb, :live_component

  alias Systems.Manual

  @impl true
  def update(%{entity: tool}, socket) do
    {
      :ok,
      socket
      |> assign(tool: tool)
      |> update_button()
      |> update_manual_builder()
    }
  end

  @impl true
  def compose(:manual_builder, %{tool: tool}) do
    %{
      module: Manual.Builder.View,
      params: %{
        title: "Manual builder",
        manual: tool.manual
      }
    }
  end

  def update_manual_builder(%{assigns: %{fabric: fabric}} = socket) do
    if Fabric.exists?(fabric, :manual_builder) do
      socket
      |> compose_child(:manual_builder)
      |> show_modal(:manual_builder, :max)
    else
      socket
    end
  end

  def update_button(%{assigns: %{tool: %{manual_id: manual_id}}} = socket)
      when not is_nil(manual_id) do
    label = dgettext("eyra-manual", "open.manual.button")

    button = %{
      action: %{type: :send, event: "open_manual"},
      face: %{type: :secondary, label: label, icon: :edit}
    }

    socket |> assign(button: button)
  end

  def update_button(%{assigns: %{tool: %{manual_id: nil}}} = socket) do
    button = %{
      action: %{type: :send, event: "create_manual"},
      face: %{type: :primary, label: dgettext("eyra-manual", "create.manual.button")}
    }

    socket |> assign(button: button)
  end

  def handle_event("create_manual", _, %{assigns: %{tool: tool}} = socket) do
    {:ok, %{manual_tool: tool}} = Manual.Assembly.create_manual(tool)

    {
      :noreply,
      socket
      |> assign(tool: tool)
      |> goto_manual_builder()
    }
  end

  def handle_event("open_manual", _, socket) do
    {
      :noreply,
      socket
      |> goto_manual_builder()
    }
  end

  defp goto_manual_builder(socket) do
    socket
    |> compose_child(:manual_builder)
    |> show_modal(:manual_builder, :max)
    |> update_button()
  end

  @impl true
  def handle_modal_closed(socket, :manual_builder) do
    socket
    |> hide_child(:manual_builder)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Button.dynamic_bar buttons={[@button]} />
    </div>
    """
  end
end
