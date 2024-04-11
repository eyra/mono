defmodule Systems.Graphite.ToolForm do
  use CoreWeb.LiveForm, :fabric
  use Fabric.LiveComponent

  import CoreWeb.Gettext
  import Frameworks.Pixel.Form

  alias Systems.Graphite

  @impl true
  def update(%{id: id, entity: entity}, socket) do
    timezone = Map.get(socket.assigns, :timezone, nil)

    {
      :ok,
      socket
      |> assign(
        id: id,
        entity: entity,
        timezone: timezone
      )
      |> update_changeset()
      |> update_leaderboard_button()
    }
  end

  def update_leaderboard_button(%{assigns: %{entity: %{leaderboard: nil}}} = socket) do
    leaderboard_button = %{
      action: %{type: :send, event: "create_leaderboard"},
      face: %{
        type: :primary,
        bg_color: "bg-tertiary",
        text_color: "text-grey1",
        label: dgettext("eyra-graphite", "leaderboard.create.button")
      }
    }

    assign(socket, leaderboard_button: leaderboard_button)
  end

  def update_leaderboard_button(
        %{assigns: %{entity: %{leaderboard: %{id: leaderboard_id}}}} = socket
      ) do
    leaderboard_button = %{
      action: %{type: :redirect, to: ~p"/graphite/leaderboard/#{leaderboard_id}/content"},
      face: %{
        type: :plain,
        icon: :forward,
        label: dgettext("eyra-graphite", "leaderboard.goto.button")
      }
    }

    assign(socket, leaderboard_button: leaderboard_button)
  end

  def update_changeset(%{assigns: %{entity: entity, timezone: timezone}} = socket) do
    changeset = Graphite.ToolModel.changeset(entity, %{}, timezone)
    assign(socket, changeset: changeset)
  end

  @impl true
  def handle_event("timezone", timezone, socket) do
    {
      :noreply,
      socket
      |> assign(timezone: timezone)
      |> update_changeset()
    }
  end

  @impl true
  def handle_event("create_leaderboard", _payload, %{assigns: %{entity: entity}} = socket) do
    Graphite.Assembly.create_leaderboard(entity)
    {:noreply, socket}
  end

  @impl true
  def handle_event("change", %{"tool_model" => attrs}, %{assigns: %{entity: entity}} = socket) do
    {:noreply, socket |> save(entity, attrs)}
  end

  def save(%{assigns: %{timezone: nil}} = socket, _entity, _attrs) do
    socket
  end

  def save(%{assigns: %{timezone: timezone}} = socket, entity, attrs) do
    changeset = Graphite.ToolModel.changeset(entity, attrs, timezone)
    save(socket, changeset)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id={"#{@id}_timezone"} class="timezone" phx-hook="TimeZone">
      <.form id={"#{@id}_graphite_tool_form"} :let={form} for={@changeset} phx-change="change" phx-target="" >
        <.datetime_input form={form} field={:deadline_string} label_text={dgettext("eyra-graphite", "deadline.label", timezone: @timezone)}/>
        <.spacing value="XS" />
        <Button.dynamic_bar buttons={[@leaderboard_button]} />
        <.spacing value="M" />
      </.form>
    </div>
    """
  end
end
