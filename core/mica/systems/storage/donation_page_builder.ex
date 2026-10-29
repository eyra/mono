defmodule Systems.Storage.DonationPageBuilder do
  use Gettext, backend: CoreWeb.Gettext

  alias CoreWeb.UI.Timestamp
  alias Frameworks.Concept
  alias Systems.Storage

  @max_rows 200

  def view_model(
        %{id: endpoint_id},
        %{branch: branch, path: path, donation: donation, timezone: timezone} = assigns
      ) do
    %{
      title: page_title(branch),
      breadcrumbs: breadcrumbs(branch),
      buttons: [back_button(endpoint_id)],
      blocks:
        [header(path, donation, timezone)] ++
          run_charts(Map.get(assigns, :run)) ++ sections(donation)
    }
  end

  # The Observatory hook builds the view model before mount reads the donation.
  def view_model(%{id: endpoint_id}, %{branch: branch}) do
    %{
      title: page_title(branch),
      breadcrumbs: breadcrumbs(branch),
      buttons: [back_button(endpoint_id)],
      blocks: []
    }
  end

  defp run_charts(nil), do: []

  defp run_charts(prompts) do
    case Storage.RunChart.charts(prompts) do
      [] ->
        []

      charts ->
        labels = Storage.RunChartSVG.labels()
        [{:run_charts, %{title: labels.title, labels: labels, charts: charts}}]
    end
  end

  defp page_title(nil), do: dgettext("eyra-storage", "tabbar.item.data")
  defp page_title(branch), do: Concept.Branch.name(branch, :self)

  defp breadcrumbs(nil), do: []
  defp breadcrumbs(branch), do: Concept.Branch.hierarchy(branch)

  defp back_button(endpoint_id) do
    %{
      action: %{type: :redirect, to: "/storage/endpoint/#{endpoint_id}/content"},
      face: %{
        type: :plain,
        label: dgettext("eyra-storage", "donation.back.button"),
        icon: :back,
        icon_align: :left
      }
    }
  end

  defp header(path, donation, timezone) do
    {:header,
     %{
       title: key_title(path),
       meta:
         [
           {dgettext("eyra-storage", "donation.participant.label"),
            Storage.Donations.participant(path) ||
              dgettext("eyra-storage", "participants.unknown")},
           {dgettext("eyra-storage", "donation.session.label"), Storage.Donations.session(path)},
           {dgettext("eyra-storage", "donation.task.label"), Storage.Donations.tool(path)}
         ] ++ file_meta(donation, timezone)
     }}
  end

  # The key without its session: the Tool's own name for what it donated.
  defp key_title(path) do
    case Storage.Donations.key(path) do
      nil -> path
      key -> key_title(key, Storage.Donations.session(path))
    end
  end

  # Without the session: "cogflex / practice1" for <run>/cogflex/practice1, "tiktok" for <session>-tiktok.
  defp key_title(key, session) do
    if String.contains?(key, "/") do
      key |> String.split("/") |> drop_session() |> Enum.join(" / ")
    else
      case String.replace_prefix(key, "#{session}-", "") do
        "" -> key
        name -> name
      end
    end
  end

  defp drop_session([_session | [_ | _] = rest]), do: rest
  defp drop_session(segments), do: segments

  defp file_meta({:ok, %{timestamp: timestamp, size: size}}, timezone) do
    [
      {dgettext("eyra-storage", "donation.stored.label"),
       timestamp |> Timestamp.convert(timezone) |> Timestamp.stamp()},
      {dgettext("eyra-storage", "donation.size.label"), format_size(size)}
    ]
  end

  defp file_meta({:error, _}, _timezone), do: []

  defp format_size(size) when size >= 1024, do: "#{Float.round(size / 1024, 1)} KB"
  defp format_size(size), do: "#{size} B"

  defp sections({:ok, %{donation: donation}}) do
    donation
    |> Storage.DonationView.blocks()
    |> sections(nil)
  end

  defp sections({:error, reason}), do: [{:message, %{text: error_text(reason)}}]

  defp sections({:table, columns, [row]}, title) do
    [{:fields, %{title: section_title(title), fields: Enum.zip(columns, cells(row))}}]
  end

  defp sections({:table, columns, rows}, title) do
    [
      {:table,
       %{
         title: section_title(title),
         count: Enum.count(rows),
         columns: columns,
         rows: rows |> Enum.take(@max_rows) |> Enum.map(&cells/1),
         truncated: truncated(Enum.count(rows))
       }}
    ]
  end

  defp sections({:tree, scalars, children}, title) do
    own = if scalars, do: sections(scalars, title), else: []
    own ++ Enum.flat_map(children, fn {key, child} -> sections(child, join(title, key)) end)
  end

  defp sections({:list, items}, title) do
    items
    |> Enum.with_index(1)
    |> Enum.flat_map(fn {item, index} -> list_item_sections(item, index, title) end)
  end

  # A top-level value, such as a declined donation's status text, is the message itself.
  defp sections({:value, value}, nil), do: [{:message, %{text: cell(value)}}]

  defp sections({:value, value}, title) do
    [{:fields, %{title: section_title(title), fields: [{title || "", cell(value)}]}}]
  end

  defp truncated(count) when count <= @max_rows, do: nil

  defp truncated(count) do
    dgettext("eyra-storage", "donation.table.truncated", shown: @max_rows, total: count)
  end

  # An item that is one named table ({"tiktok_comments": [...]}) is titled by that name, not its index.
  defp list_item_sections({:tree, nil, [{key, child}]}, _index, title),
    do: sections(child, join(title, key))

  defp list_item_sections(item, index, title), do: sections(item, join(title, "#{index}"))

  defp join(nil, key), do: key
  defp join(title, key), do: "#{title} / #{key}"

  defp section_title(nil), do: details_title()

  # "tiktok_video_browsing_history / data" reads as "Tiktok video browsing history / data".
  defp section_title(title) do
    {first, rest} = title |> String.replace("_", " ") |> String.split_at(1)
    String.upcase(first) <> rest
  end

  defp details_title, do: dgettext("eyra-storage", "donation.details.title")

  defp cells(row), do: Enum.map(row, &cell/1)

  defp cell(nil), do: "–"
  defp cell(values) when is_list(values), do: Enum.map_join(values, ", ", &cell/1)
  defp cell(value), do: to_string(value)

  defp error_text(:not_found), do: dgettext("eyra-storage", "donation.error.not_found")
  defp error_text(:too_large), do: dgettext("eyra-storage", "donation.error.too_large")
  defp error_text(_reason), do: dgettext("eyra-storage", "donation.error.unreadable")
end
