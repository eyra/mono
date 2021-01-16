defmodule LinkWeb.SurveyTool.Index do
  @moduledoc """
  The home screen.
  """
  use LinkWeb, :live_view
  use LinkWeb.LiveViewPowHelper
  alias Link.SurveyTools
  alias Link.SurveyTools.SurveyTool

  data survey_tools, :any
  data study, :any
  data changeset, :any
  data saved, :boolean

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(survey_tools: SurveyTools.list_survey_tools())

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <h1>Listing Survey tools</h1>

    <table>
    <thead>
    <tr>
      <th colspan="2">Title</th>
    </tr>
    </thead>
    <tbody>
    <tr :for={{survey_tool <- @survey_tools}}>
      <td>{{ survey_tool.title }}</td>
      <td>
        <span>{{ link "Show", to: Routes.live_path(@socket, __MODULE__) }}</span>
        <span fixme="can?(@socket, [survey_tool], LinkWeb.SurveyToolController, :edit)">
        {{ link "Edit", to: Routes.live_path(@socket,  LinkWeb.SurveyTool.Edit, survey_tool.id) }}
        </span>
        <span>{{ link "Delete", to: Routes.live_path(@socket, __MODULE__), method: :delete, data: [confirm: "Are you sure?"] }}</span>
      </td>
    </tr>
    </tbody>
    </table>

    <span>{{ link "New Survey tool", to: Routes.live_path(@socket, __MODULE__) }}</span>

    """
  end
end
