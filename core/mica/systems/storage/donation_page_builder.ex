defmodule Systems.Storage.DonationPageBuilder do
  use Gettext, backend: CoreWeb.Gettext

  alias CoreWeb.UI.Timestamp
  alias Frameworks.Concept
  alias Systems.Storage

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
          run_chart(Map.get(assigns, :run), Map.get(assigns, :column)) ++ sections(donation)
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

  defp run_chart(nil, _column), do: []

  defp run_chart(prompts, requested) do
    case Storage.RunChart.column(prompts, requested) do
      nil ->
        []

      column ->
        [
          {:run_chart,
           %{
             title: dgettext("eyra-storage", "donation.chart.title"),
             column_label: dgettext("eyra-storage", "donation.chart.column.label"),
             x_label: dgettext("eyra-storage", "donation.chart.x.label"),
             columns: Storage.RunChart.columns(prompts),
             column: column,
             chart: Storage.RunChart.build(prompts, column)
           }}
        ]
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
      key -> key |> String.split("/") |> drop_session() |> Enum.join(" / ")
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
         rows: Enum.map(rows, &cells/1)
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
    |> Enum.flat_map(fn {item, index} -> sections(item, join(title, "#{index}")) end)
  end

  defp sections({:value, value}, title) do
    [{:fields, %{title: section_title(title), fields: [{title || "", cell(value)}]}}]
  end

  defp join(nil, key), do: key
  defp join(title, key), do: "#{title} / #{key}"

  defp section_title(nil), do: details_title()

  defp section_title(title) do
    {first, rest} = String.split_at(title, 1)
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
