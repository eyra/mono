defmodule Systems.Userflow.StepForm do
  use CoreWeb.LiveForm

  alias Systems.Userflow

  @impl true
  def update(%{step: step, group_label: group_label}, socket) do
    {
      :ok,
      socket
      |> assign(
        entity: step,
        group_label: group_label
      )
      |> update_changeset()
    }
  end

  def update_changeset(%{assigns: %{entity: entity}} = socket) do
    changeset =
      if entity do
        Userflow.StepModel.changeset(entity, %{})
      else
        nil
      end

    socket |> assign(changeset: changeset)
  end

  @impl true
  def handle_event("save", %{"step_model" => attrs}, %{assigns: %{entity: entity}} = socket) do
    changeset = Userflow.StepModel.changeset(entity, attrs)

    {
      :noreply,
      socket
      |> save(changeset)
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%= if @entity do %>
        <.form id={@id} :let={form} for={@changeset} phx-change="save" phx-target={@myself} >
          <.text_input form={form} field={:group} label_text={@group_label} />
        </.form>
      <% end %>
    </div>
    """
  end
end
