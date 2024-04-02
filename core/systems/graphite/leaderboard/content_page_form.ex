defmodule Systems.Graphite.Leaderboard.ContentPageForm do
  use CoreWeb.LiveForm, :fabric
  use Fabric.LiveComponent

  import Frameworks.Pixel.Form

  alias Frameworks.Pixel.Text

  alias Systems.Graphite

  @impl true
  def update(
        %{
          id: id,
          leaderboard: leaderboard
        },
        socket
      ) do
    changeset = Graphite.LeaderboardModel.changeset(leaderboard, %{})

    {
      :ok,
      socket
      |> assign(
        id: id,
        leaderboard: leaderboard,
        changeset: changeset
      )
    }
  end

  def handle_event("save", %{"leaderboard_model" => attrs}, socket) do
    %{assigns: %{leaderboard: leaderboard}} = socket

    attrs =
      if attrs["metrics"] do
        Map.put(attrs, "metrics", String.split(attrs["metrics"], ",", trim: true))
      else
        Map.put(attrs, "metrics", [])
      end

    {
      :noreply,
      socket
      |> save(leaderboard, attrs)
    }
  end

  defp save(socket, entity, attrs) do
    changeset = Graphite.LeaderboardModel.changeset(entity, attrs)

    socket
    |> save(changeset)
  end

  @impl true
  def render(assigns) do
    visibility_options = [
      %{id: "public", value: :public, active: true},
      %{id: "private", value: :private, active: false},
      %{id: "private_with_date", value: "private with date", active: false}
    ]

    ~H"""
      <div>
        <.form id={"#{@id}_general"} :let={form} for={@changeset} phx-change="save" phx-target={@myself} >
          <Text.title3>Leaderboard settings</Text.title3>
          <.text_input form={form} field={:name} label_text="Name" />
          <.text_input form={form} field={:version} label_text="Version" />
          <.number_input form={form} field={:tool_id} label_text="Challenge ID" />
          <.list_input form={form} field={:metrics} label_text="Metrics" value={Enum.join(@changeset.data.metrics, ",")} />
          <.radio_group form={form} field={:visibility} items={visibility_options} label_text="Visibility" />
          <.radio_group form={form} field={:allow_anonymous} items={[%{value: true, active: true, id: "true"}, %{value: false, active: false, id: "false"}]} label_text="Allow anonymous" />
        </.form>
      </div>
    """
  end
end
