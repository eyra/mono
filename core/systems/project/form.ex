defmodule Systems.Project.Form do
  use CoreWeb.LiveForm

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
      |> update_text()
      |> update_buttons()
    }
  end

  defp update_text(socket) do
    assign(socket, text: dgettext("eyra-project", "form.text"))
  end

  defp update_buttons(%{assigns: %{myself: myself}} = socket) do
    submit = %{
      action: %{type: :send, target: myself, event: "submit"},
      face: %{type: :primary, label: dgettext("eyra-ui", "submit.button")}
    }

    assign(socket, buttons: [submit])
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
      <div class="text-title5 font-title5 sm:text-title3 sm:font-title3">
        <%= dgettext("eyra-project", "form.title") %>
      </div>
      <.spacing value="S" />
      <div id={"#{@id}_project_content"} phx-hook="LiveContent" data-show-errors={@show_errors}>
        <.form id={@id} :let={form} for={@changeset} phx-submit="submit" phx-change="change" phx-target={@myself} >
          <.text_input form={form} field={:name} debounce="0" />
        </.form>
      </div>
      <div class="flex flex-row gap-4">
        <%= for button <- @buttons do %>
          <Button.dynamic {button} />
        <% end %>
      </div>
    </div>
    """
  end
end
