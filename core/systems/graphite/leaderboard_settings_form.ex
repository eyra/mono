defmodule Systems.Graphite.LeaderboardSettingsForm do
  use CoreWeb.LiveForm, :fabric
  use Fabric.LiveComponent

  import Frameworks.Pixel.Form

  alias Frameworks.Pixel.Text

  alias Systems.Graphite

  @visibility_options [
    %{id: "public", value: "public", active: true},
    %{id: "private", value: "private", active: false}
  ]

  @impl true
  def update(%{id: id, leaderboard: leaderboard}, socket) do
    changeset = Graphite.LeaderboardModel.changeset(leaderboard, %{})

    {
      :ok,
      socket
      |> assign(
        id: id,
        leaderboard: leaderboard,
        changeset: changeset,
        visibility_options: @visibility_options
      )
    }
  end

  @impl true
  def handle_event("save", %{"leaderboard_model" => attrs}, socket) do
    %{assigns: %{leaderboard: leaderboard}} = socket

    attrs =
      if attrs["metrics"] do
        Map.put(attrs, "metrics", string_to_metrics(attrs["metrics"]))
      else
        attrs
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

  defp metrics_to_string(nil), do: ""
  defp metrics_to_string(metrics), do: Enum.join(metrics, ",")

  defp string_to_metrics(metric_str) do
    metric_str
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form id={"#{@id}_settings"} :let={form} for={@changeset} phx-change="save" phx-target={@myself} >
        <.spacing value="L" />
        <Text.title2>Settings</Text.title2>
        <.text_input form={form} field={:title} label_text={dgettext("eyra-graphite", "label.title")} />
        <.text_input form={form} field={:subtitle} label_text={dgettext("eyra-graphite", "label.subtitle")} />
        <.list_input form={form} field={:metrics} label_text={dgettext("eyra-graphite", "label.metrics")} value={metrics_to_string(@changeset.data.metrics)} />
        <Text.hint><%= dgettext("eyra-graphite", "settings.form.metrics.hint") %></Text.hint>
        <.spacing value="M"/>
        <.radio_group form={form} field={:visibility} items={@visibility_options} label_text="Visibility" />
      </.form>
    </div>
    """
  end
end
