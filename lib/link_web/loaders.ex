defmodule LinkWeb.Loaders do
  @moduledoc """
  The loaders for the Link application. They integrate with the GreenLight
  framework.
  """

  def study!(_conn, params, as_parent) do
    study =
      case {as_parent, params} do
        {true, %{"study_id" => study_id}} ->
          Link.Studies.get_study!(study_id |> String.to_integer())

        {false, %{"id" => study_id}} ->
          Link.Studies.get_study!(study_id |> String.to_integer())

        _ ->
          nil
      end

    {:study, study}
  end

  def survey_tool!(_conn, params, as_parent) do
    survey_tool =
      case {as_parent, params} do
        {true, %{"survey_tool_id" => survey_tool_id}} ->
          Link.SurveyTools.get_survey_tool!(survey_tool_id |> String.to_integer())

        {false, %{"id" => survey_tool_id}} ->
          Link.SurveyTools.get_survey_tool!(survey_tool_id |> String.to_integer())

        _ ->
          nil
      end

    {:survey_tool, survey_tool}
  end
end
