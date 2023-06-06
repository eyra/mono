defmodule Systems.Project.ConfigForm do
  use CoreWeb.LiveForm

  alias Systems.{
    Project,
    DataDonation
  }

  # Handle initial update
  @impl true
  def update(
        %{id: id, entity: project},
        socket
      ) do
    changeset = Project.Model.changeset(project, %{})

    {
      :ok,
      socket
      |> assign(
        id: id,
        entity: project,
        changeset: changeset,
        data_donation_tool_id: nil
      )
      |> update_data_donation_tool_id()
    }
  end

  defp update_data_donation_tool_id(
         %{
           assigns: %{
             entity: %{
               root: %{
                 items: [
                   %{
                     tool_ref: %{
                       data_donation_tool_id: data_donation_tool_id
                     }
                   }
                 ]
               }
             }
           }
         } = socket
       ) do
    assign(socket, data_donation_tool_id: data_donation_tool_id)
  end

  # Handle Events
  @impl true
  def handle_event("save", %{"model" => attrs}, %{assigns: %{entity: entity}} = socket) do
    {
      :noreply,
      socket
      |> save(entity, attrs)
    }
  end

  # Saving

  def save(socket, entity, attrs) do
    changeset = Project.Model.changeset(entity, attrs)

    socket
    |> save(changeset)
    |> update_tabbar()
  end

  # Tabbar update
  def update_tabbar(%{assigns: %{id: id, changeset: changeset}} = socket) do
    send(self(), %{id: id, ready?: changeset.valid?})

    socket
    |> assign(changeset: changeset)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
      <Margin.y id={:page_top} />
        <Text.title2><%= dgettext("eyra-project", "config.title")  %></Text.title2>
        <.form id={@id} :let={form} for={@changeset} phx-change="save" phx-target={@myself} >
          <.text_input form={form} field={:name} label_text={dgettext("eyra-project", "form.name.label")} />
        </.form>

        <.live_component
          id={:tool_form}
          module={DataDonation.ToolForm}
          entity_id={@data_donation_tool_id}
        />
      </Area.content>
    </div>
    """
  end
end
