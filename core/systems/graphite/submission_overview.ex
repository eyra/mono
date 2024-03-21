defmodule Systems.Graphite.SubmissionOverview do
  use CoreWeb, :live_component

  alias Systems.{
    Graphite
  }

  @impl true
  def update(%{id: id, entity: %{id: tool_id}}, socket) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        tool_id: tool_id
      )
      |> prepare_export_button()
      |> update_submissions()
      |> update_submission_items()
    }
  end

  defp prepare_export_button(%{assigns: %{tool_id: tool_id}} = socket) do
    export_button = %{
      action: %{
        type: :http_get,
        to: ~p"/graphite/#{tool_id}/export/submissions",
        target: "_blank"
      },
      face: %{type: :label, label: "Export", icon: :export}
    }

    assign(socket, export_button: export_button)
  end

  defp update_submissions(%{assigns: %{tool_id: tool_id}} = socket) do
    submissions = Graphite.Public.list_submissions(tool_id, [:spot])
    assign(socket, submissions: submissions)
  end

  defp update_submission_items(%{assigns: %{submissions: submissions}} = socket) do
    submission_items = Enum.map(submissions, &to_item/1)
    assign(socket, submission_items: submission_items)
  end

  defp to_item(%{
         spot: %{name: name},
         description: description,
         github_commit_url: github_commit_url,
         updated_at: updated_at
       }) do
    summary =
      updated_at
      |> CoreWeb.UI.Timestamp.apply_timezone()
      |> CoreWeb.UI.Timestamp.humanize()
      |> Macro.camelize()

    %{
      team: name,
      description: description,
      summary: summary,
      url: github_commit_url,
      buttons: []
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
        <Margin.y id={:page_top} />
        <div class="flex flex-row">
          <Text.title2>
            <%= dgettext("eyra-benchmark", "tabbar.item.submissions")%> <span class="text-primary"> <%= Enum.count(@submission_items) %></span>
          </Text.title2>
          <div class="flex-grow" />
          <Button.dynamic {@export_button} />
        </div>
        <Graphite.SubmissionView.list items={@submission_items} />
      </Area.content>
    </div>
    """
  end
end
