defmodule Systems.Graphite.Leaderboard.Overview do
  use CoreWeb, :live_component

  alias Systems.{
    Graphite
  }

  @impl true
  def update(%{csv_lines: csv_lines}, socket) do
    Graphite.Public.import_csv_lines(csv_lines)

    {
      :ok,
      socket
      |> update_leaderboard()
    }
  end

  @impl true
  def update(%{id: id, entity: entity}, socket) do
    import_form = %{
      id: :import_form,
      module: Graphite.ImportForm,
      parent: %{type: __MODULE__, id: id},
      placeholder: dgettext("eyra-benchmark", "csv-select-placeholder"),
      select_button: dgettext("eyra-benchmark", "csv-select-file-button"),
      replace_button: dgettext("eyra-benchmark", "csv-replace-file-button"),
      process_button: dgettext("eyra-benchmark", "csv-import-button")
    }

    {
      :ok,
      socket
      |> assign(
        id: id,
        entity: entity,
        import_form: import_form
      )
      |> update_leaderboard()
      |> update_forward_button()
    }
  end

  defp update_leaderboard(%{assigns: %{entity: %{id: tool_id}}} = socket) do
    categories =
      Graphite.Public.list_leaderboard_categories(tool_id, scores: [submission: [:spot]])

    leaderboard = %{
      id: :leaderboard,
      module: Graphite.LeaderboardView,
      categories: categories
    }

    assign(socket, leaderboard: leaderboard)
  end

  defp update_forward_button(%{assigns: %{entity: %{id: tool_id}}} = socket) do
    forward_button = %{
      action: %{
        type: :http_get,
        to: ~p"/graphite/#{tool_id}/public/leaderboard",
        target: "_blank"
      },
      face: %{
        type: :plain,
        label: dgettext("eyra-benchmark", "leaderboard.forward.button"),
        icon: :forward
      }
    }

    assign(socket, forward_button: forward_button)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
        <Margin.y id={:page_top} />
        <div class="flex flex-row items-center justify-center">
          <Text.title2 margin=""><%= dgettext("eyra-benchmark", "tabbar.item.leaderboard")%></Text.title2>
          <div class="flex-grow" />
          <Button.dynamic {@forward_button} />
        </div>
        <.spacing value="M" />
        <.live_component {@leaderboard} />
        <.spacing value="XL" />
        <Text.title4><%= dgettext("eyra-benchmark", "import.leaderboard.title")%></Text.title4>
        <.spacing value="S" />
        <.live_component {@import_form} />
      </Area.content>
    </div>
    """
  end
end
