defmodule Systems.Graphite.Leaderboard.SettingsView do
  use CoreWeb, :live_component_fabric
  use Fabric.LiveComponent

  alias Systems.Graphite

  @impl true
  def update(
        %{
          id: id,
          entity: leaderboard,
          uri_origin: uri_origin,
          viewport: viewport,
          breakpoint: breakpoint
        },
        socket
      ) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        entity: leaderboard,
        uri_origin: uri_origin,
        viewport: viewport,
        breakpoint: breakpoint
      )
      |> compose_child(:settings)
    }
  end

  @impl true
  defp compose(:settings, %{entity: leaderboard}) do
    %{
      module: Graphite.Leaderboard.ContentPageForm,
      params: %{
        leaderboard: leaderboard,
        page_key: :leaderboard_intro,
        opt_in?: false,
        on_text: dgettext("eyra-assignment", "intro_form.on.label"),
        off_text: dgettext("eyra-assignment", "intro_form.off.label")
      }
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
      <Area.content>
        <Margin.y id={:page_top} />
        <Text.title2><%= dgettext("eyra-assignment", "settings.title") %></Text.title2>
        <.spacing value="L" />
        <.child name={:settings} fabric={@fabric} >
          <:header>
            Change the leaderboard settings here.
            <.spacing value="M" />
          </:header>
          <:footer>
            <.spacing value="L" />
          </:footer>
        </.child>
      </Area.content>
      </div>
    """
  end
end
