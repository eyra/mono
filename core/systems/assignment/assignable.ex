defmodule Systems.Assignment.Assignable do
  import CoreWeb.Gettext

  def languages(%{language: language}) when not is_nil(language), do: [language]
  def languages(_), do: []

  def devices(%{devices: devices}) when not is_nil(devices), do: devices
  def devices(_), do: []

  def spot_count(%{subject_count: subject_count}) when not is_nil(subject_count),
    do: subject_count

  def spot_count(_), do: 0

  def duration(%{duration: duration}) when not is_nil(duration) do
    case Integer.parse(duration) do
      :error -> 0
      {duration, _} -> duration
    end
  end

  def duration(_), do: 0

  def apply_label(%{survey_tool: tool}) when not is_nil(tool),
    do: dgettext("link-survey", "apply.cta.title")

  def apply_label(_), do: "<apply>"

  def open_label(%{survey_tool: tool}) when not is_nil(tool),
    do: dgettext("link-survey", "open.cta.title")

  def open_label(_), do: "<open>"

  def ready?(%{survey_tool: tool}) when not is_nil(tool), do: Systems.Survey.Context.ready?(tool)
  def ready?(%{lab_tool: tool}) when not is_nil(tool), do: Systems.Lab.Context.ready?(tool)

  def path(%{survey_tool: %{survey_url: survey_url}}, panl_id) when not is_nil(survey_url) do
    url_components = URI.parse(survey_url)

    query =
      url_components.query
      |> decode_query()
      |> Map.put(:panl_id, panl_id)
      |> URI.encode_query(:rfc3986)

    url_components
    |> Map.put(:query, query)
    |> URI.to_string()
  end

  def path(_, _), do: nil

  defp decode_query(nil), do: %{}
  defp decode_query(query), do: URI.decode_query(query)
end
