defmodule Systems.Graphite.LeaderboardUploadForm do
  use CoreWeb.LiveForm, :fabric
  use Fabric.LiveComponent

  alias Frameworks.Pixel.Text

  alias Systems.{
    Graphite
  }

  @impl true
  def update(%{id: id, leaderboard: leaderboard}, socket) do
    {
      :ok,
      socket
      |> assign(id: id, leaderboard: leaderboard)
    }
  end

  @impl true
  def handle_event("save", %{"leaderboard_model" => attrs}, socket) do
    %{assigns: %{leaderboard: leaderboard}} = socket

    {
      :noreply,
      socket
      |> save(leaderboard, attrs)
    }
  end

  defp save(socket, entity, attrs) do
    # No longer needed, change to dealing with upload
    changeset = Graphite.LeaderboardModel.changeset(entity, attrs)

    socket
    |> save(changeset)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form id={"#{@id}_settings"} :let={_form} for={%{}} phx-change="save" phx-target={@myself} >
        <.spacing value="L" />
        <Text.title2>Upload results</Text.title2>
      </.form>
    </div>
    """
  end
end
