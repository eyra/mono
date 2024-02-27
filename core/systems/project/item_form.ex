defmodule Systems.Project.ItemForm do
  use CoreWeb.LiveForm, :fabric
  use Fabric.LiveComponent

  import CoreWeb.UI.Dialog

  alias Systems.{
    Project
  }

  # Handle initial update
  @impl true
  def update(
        %{id: id, item: item},
        socket
      ) do
    changeset = Project.ItemModel.changeset(item, %{})

    {
      :ok,
      socket
      |> assign(
        id: id,
        item: item,
        changeset: changeset,
        show_errors: false
      )
      |> update_title()
      |> update_buttons()
    }
  end

  defp update_title(socket) do
    assign(socket, title: dgettext("eyra-project", "item.form.title"))
  end

  defp update_buttons(%{assigns: %{myself: myself}} = socket) do
    assign(socket, buttons: form_dialog_buttons(myself))
  end

  def handle_view_model_updated(socket) do
    socket
  end

  # Handle Events

  @impl true
  def handle_event("change", %{"item_model" => attrs}, %{assigns: %{item: item}} = socket) do
    changeset = Project.ItemModel.changeset(item, attrs)

    {
      :noreply,
      socket |> assign(changeset: changeset)
    }
  end

  @impl true
  def handle_event("submit", _, socket) do
    {:noreply, socket |> submit_form()}
  end

  @impl true
  def handle_event("cancel", _, socket) do
    {:noreply, socket |> finish()}
  end

  # Submit

  defp submit_form(%{assigns: %{item: item, changeset: changeset}} = socket) do
    case Core.Persister.save(item, changeset) do
      {:ok, _} ->
        socket |> finish()

      {:error, changeset} ->
        socket
        |> assign(show_errors: true)
        |> assign(changeset: changeset)
    end
  end

  defp finish(socket) do
    socket |> send_event(:parent, "finish")
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.dialog {%{title: @title, buttons: @buttons}}>
        <div id={"#{@id}_project_item_content"} phx-hook="LiveContent" data-show-errors={@show_errors}>
          <.form id={@id} :let={form} for={@changeset} phx-submit="submit" phx-change="change" phx-target={@myself} >
            <.text_input form={form} field={:name} label_text={dgettext("eyra-project", "item.form.name.label")} debounce="0" />
          </.form>
        </div>
      </.dialog>
    </div>
    """
  end
end
