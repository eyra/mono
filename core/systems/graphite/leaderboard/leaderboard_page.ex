defmodule Systems.Graphite.LeaderboardPage do
  alias DigitalToken.Data
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Stripped.Component, :onboarding

  alias Frameworks.Pixel.Align

  alias Systems.{
    Graphite
  }

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {
      :ok,
      socket
      |> assign(id: id)
      |> update_title()
      |> update_leaderboard()
      |> update_forward_button()
    }
  end

  def mount(%{"leaderboard_id" => id}, _session, socket) do
    {
      :ok,
      socket
      |> assign(id: id)
      |> update_leaderboard()
      |> update_title()
      |> update_forward_button()
    }
  end

  defp update_title(socket) do
    assign(socket, title: socket.assigns.leaderboard.name)
  end

  defp update_forward_button(%{assigns: %{id: tool_id}} = socket) do
    forward_button = %{
      action: %{type: :http_get, to: ~p"/graphite/#{tool_id}"},
      face: %{
        type: :plain,
        label: dgettext("eyra-benchmark", "challenge.forward.button"),
        icon: :forward
      }
    }

    assign(socket, forward_button: forward_button)
  end

  defp update_leaderboard(%{assigns: %{id: leaderboard_id}} = socket) do
    leaderboard = Graphite.Public.get_leaderboard!(leaderboard_id, [{:scores, :submission}])

    categories =
      Enum.map(
        leaderboard.metrics,
        fn metric ->
          %{
            name: metric,
            scores: leaderboard.scores |> Enum.filter(&(&1.metric == metric))
          }
        end
      )

    leaderboard_live = %{
      id: :leaderboard_live,
      open: information_open?(leaderboard.open_date),
      module: Graphite.LeaderboardView,
      categories: categories
    }

    socket
    |> assign(:leaderboard_live, leaderboard_live)
    |> assign(:leaderboard, leaderboard)
  end

  defp information_open?(nil), do: true

  defp information_open(datetime) do
    NaiveDateTime.diff(datetime, NaiveDateTime.local_now()) > 0
  end

  @impl true
  def render(assigns) do
    ~H"""
      <.stripped title="Leaderboard" menus={@menus}>
        <.spacing value="XL" />
        <Area.content>
          <div class="flex flex-row space-x-4">
            <div class="basis-1/3 bg-grey5 px-4 py-2">
              <Text.body_large><div class="text-center">Number of submissions</div></Text.body_large>
              <Text.body_large><div class="text-center"><%= "bla" %></div></Text.body_large>
            </div>
            <div class="basis-1/3 bg-grey5 px-4 py-2">
              <Text.body_large><div class="text-center">Generated on</div></Text.body_large>
              <Text.body_large><div class="text-center"> <%= NaiveDateTime.to_date(@leaderboard.generation_date) %> </div></Text.body_large>
            </div>
            <div class="basis-1/3 bg-grey5 px-4 py-2">
              <Text.body_large><div class="text-center">Opening up in</div></Text.body_large>
              <Text.body_large><div class="text-center">? days</div></Text.body_large>
            </div>
          </div>
        </Area.content>

        <.spacing value="XL" />
        <Area.content>
          <Text.title2>Description</Text.title2>
          <Text.title3>Research problem</Text.title3>

          <Text.title3>Purpuse statement</Text.title3>

          <Text.title3>Data</Text.title3>

          <Text.title3>Metrics</Text.title3>
        </Area.content>

        <Area.content>
          <Margin.y id={:page_top} />
          <Text.title2><%= @title %></Text.title2>
          There are X anonymous submissions for this challenge that are not shown on this leaderboard.
          <.spacing value="M" />
          <.live_component {@leaderboard_live} />
          <.spacing value="XL" />
          <Button.dynamic {@forward_button} />
        </Area.content>
      </.stripped>
    """
  end
end
