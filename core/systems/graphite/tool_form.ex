defmodule Systems.Graphite.ToolForm do
  use CoreWeb.LiveForm

  alias Systems.{
    Graphite
  }

  # Handle initial update
  @impl true
  def update(
        %{id: id, entity: benchmark},
        socket
      ) do
    changeset = Graphite.ToolModel.changeset(benchmark, %{})

    {
      :ok,
      socket
      |> assign(
        id: id,
        entity: benchmark,
        changeset: changeset
      )
    }
  end

  # Handle Events
  @impl true
  def handle_event("save", %{"tool_model" => attrs}, %{assigns: %{entity: entity}} = socket) do
    {
      :noreply,
      socket
      |> save(entity, attrs)
    }
  end

  # Saving

  def save(socket, entity, attrs) do
    changeset = Graphite.ToolModel.changeset(entity, attrs)

    socket
    |> save(changeset)
    |> validate(changeset)
  end

  def validate(socket, changeset) do
    changeset = Graphite.ToolModel.validate(changeset)

    socket
    |> assign(changeset: changeset)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form id={"#{@id}_graphite_tool_form"} :let={form} for={@changeset} phx-change="save" phx-target={@myself} >
        <.text_input form={form} field={:title} label_text={dgettext("eyra-benchmark", "form.title.label")} />
        <.text_area form={form} field={:expectations} label_text={dgettext("eyra-benchmark", "form.expectations.label")} />
        <.url_input form={form} field={:data_set} label_text={dgettext("eyra-benchmark", "form.data_set.label")} />
        <.url_input form={form} field={:template_repo} label_text={dgettext("eyra-benchmark", "form.template_repo.label")} />
        <.date_input form={form} field={:deadline} label_text={dgettext("eyra-benchmark", "form.deadline.label")} />
      </.form>
    </div>
    """
  end
end
