defmodule Systems.Project.Form do
  use CoreWeb.LiveForm

  import CoreWeb.UI.Dialog

  alias Systems.{
    Project
  }

  # Handle initial update
  @impl true
  def update(
        %{id: id, project: project},
        socket
      ) do
    changeset = Project.Model.changeset(project, %{})

    {
      :ok,
      socket
      |> assign(
        id: id,
        project: project,
        changeset: changeset,
        show_errors: false
      )
      |> update_title()
      |> update_text()
      |> update_buttons()
    }
  end

  defp update_title(socket) do
    assign(socket, title: dgettext("eyra-project", "form.title"))
  end

  defp update_text(socket) do
    assign(socket, text: dgettext("eyra-project", "form.text"))
  end

  defp update_buttons(%{assigns: %{myself: myself}} = socket) do
    assign(socket, buttons: form_dialog_buttons(myself))
  end

  # Handle Events

  @impl true
  def handle_event("change", %{"model" => attrs}, %{assigns: %{project: project}} = socket) do
    changeset = Project.Model.changeset(project, attrs)

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

  defp submit_form(%{assigns: %{project: project, changeset: changeset}} = socket) do
    case Core.Persister.save(project, changeset) do
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
      <div id={"#{@id}_project_content"} phx-hook="LiveContent" data-show-errors={@show_errors}>
          <.form id={@id} :let={form} for={@changeset} phx-submit="submit" phx-change="change" phx-target={@myself} >
            <.text_input form={form} field={:name} label_text={dgettext("eyra-project", "form.name.label")} debounce="0" />
          </.form>
        </div>
      </.dialog>
    </div>
    """
  end
end
