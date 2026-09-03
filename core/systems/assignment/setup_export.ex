defmodule Systems.Assignment.SetupExport do
  @moduledoc """
  Serializes the configuration of an assignment for the study setup export.

  `metadata/2` is pure: it takes a loaded assignment and returns the
  `next-metadata.json` contents together with the assets that contents refers
  to. Every `assets/...` path in the map originates from an entry in the asset
  list, so the two cannot drift apart.
  """

  alias Frameworks.Concept
  alias Systems.Alliance
  alias Systems.Assignment
  alias Systems.Content
  alias Systems.Document
  alias Systems.Feldspar
  alias Systems.Manual
  alias Systems.Workflow

  @format_version 1
  @header_image_size {1376, 720}
  @max_asset_bytes 50_000_000

  def preload_graph do
    [
      :info,
      :privacy_doc,
      page_refs: [:page],
      consent_agreement: [:revisions],
      workflow: [items: [tool_ref: Workflow.ToolRefModel.preload_graph(:down)]]
    ]
  end

  @doc """
  Packmatic entries for the whole export: the metadata document plus one entry
  per configured asset, all nested under `folder`.
  """
  def entries(%Assignment.Model{} = assignment, name, folder) do
    {metadata, assets} = metadata(assignment, name)

    [metadata_entry(metadata, folder) | Enum.map(assets, &asset_entry(&1, folder))]
  end

  defp metadata_entry(metadata, folder) do
    [
      source: {:stream, [Jason.encode!(metadata, pretty: true)]},
      path: "#{folder}/next-metadata.json",
      timestamp: DateTime.utc_now()
    ]
  end

  defp asset_entry(%{path: path, url: url}, folder) do
    [
      source: asset_source(url),
      path: "#{folder}/#{path}",
      timestamp: DateTime.utc_now()
    ]
  end

  defp asset_source(url) do
    case Content.Public.get_local_path(url) do
      nil -> {:url, {url, [], [max_body_length: @max_asset_bytes]}}
      path -> {:file, path}
    end
  end

  def metadata(%Assignment.Model{id: id, info: info, page_refs: page_refs} = assignment, name) do
    {branding, branding_assets} = branding(info)
    {privacy_statement_pdf, privacy_assets} = privacy_statement(assignment)
    {tasks, task_assets} = tasks(assignment)

    {
      %{
        format_version: @format_version,
        assignment: %{id: id, name: name},
        language: Assignment.Model.language(assignment),
        branding: branding,
        about: page_body(page_refs, :assignment_information),
        consent: consent(assignment),
        helpdesk: page_body(page_refs, :assignment_helpdesk),
        privacy_statement_pdf: privacy_statement_pdf,
        workflow: %{tasks: tasks}
      },
      branding_assets ++ privacy_assets ++ task_assets
    }
  end

  defp branding(nil), do: {empty_branding(), []}

  defp branding(%Assignment.InfoModel{title: title, subtitle: subtitle} = info) do
    {logo, logo_assets} = asset(info.logo_url, "logo")

    {
      %{title: title, subtitle: subtitle, logo: logo, header_image: header_image_url(info)},
      logo_assets
    }
  end

  defp empty_branding, do: %{title: nil, subtitle: nil, logo: nil, header_image: nil}

  defp header_image_url(%Assignment.InfoModel{image_id: nil}), do: nil

  defp header_image_url(%Assignment.InfoModel{image_id: image_id}) do
    {width, height} = @header_image_size
    Core.ImageHelpers.get_image_info(image_id, width, height).url
  end

  defp privacy_statement(%Assignment.Model{privacy_doc: %{ref: ref}}),
    do: asset(ref, "privacy-statement")

  defp privacy_statement(%Assignment.Model{}), do: {nil, []}

  defp consent(%Assignment.Model{consent_agreement: %{revisions: revisions}})
       when is_list(revisions) do
    case Enum.max_by(revisions, & &1.id, fn -> nil end) do
      %{source: source} -> source
      nil -> nil
    end
  end

  defp consent(%Assignment.Model{}), do: nil

  defp page_body(page_refs, key) when is_list(page_refs) do
    case Enum.find(page_refs, &(&1.key == key)) do
      %{page: %{body: body}} -> body
      _ -> nil
    end
  end

  defp page_body(_page_refs, _key), do: nil

  defp tasks(%Assignment.Model{workflow: %Workflow.Model{items: items} = workflow})
       when is_list(items) do
    workflow
    |> Workflow.Model.ordered_items()
    |> Enum.with_index(1)
    |> Enum.map(&task/1)
    |> unzip_assets()
  end

  defp tasks(%Assignment.Model{}), do: {[], []}

  defp task(
         {%Workflow.ItemModel{title: title, description: description, tool_ref: tool_ref}, index}
       ) do
    {fields, assets} =
      tool_ref
      |> Workflow.ToolRefModel.tool()
      |> tool_fields(index)

    {Map.merge(%{title: title, description: description}, fields), assets}
  end

  defp tool_fields(%Alliance.ToolModel{url: url}, _index),
    do: {%{type: "questionnaire", link: url}, []}

  defp tool_fields(%Feldspar.ToolModel{archive_name: archive_name}, _index),
    do: {%{type: "data_donation", filename: archive_name}, []}

  defp tool_fields(%Manual.ToolModel{manual: manual}, index), do: manual_fields(manual, index)

  defp tool_fields(%Document.ToolModel{name: name, ref: ref}, index) do
    {file, assets} = asset(ref, "document-#{index}")
    {%{type: "document", filename: name, file: file}, assets}
  end

  defp tool_fields(nil, _index), do: {%{type: "unknown"}, []}

  defp tool_fields(tool, _index), do: {%{type: to_string(Concept.ToolModel.key(tool))}, []}

  defp manual_fields(
         %Manual.Model{title: title, description: description, chapters: chapters},
         index
       )
       when is_list(chapters) do
    {chapters, assets} =
      chapters
      |> sort_by_step()
      |> Enum.with_index(1)
      |> Enum.map(&chapter(&1, index))
      |> unzip_assets()

    {%{
       type: "instruction_manual",
       manual_title: title,
       manual_description: description,
       chapters: chapters
     }, assets}
  end

  defp manual_fields(_manual, _index), do: {%{type: "instruction_manual", chapters: []}, []}

  defp chapter({%Manual.ChapterModel{title: title, pages: pages}, chapter_index}, task_index)
       when is_list(pages) do
    {pages, assets} =
      pages
      |> sort_by_step()
      |> Enum.with_index(1)
      |> Enum.map(&page(&1, task_index, chapter_index))
      |> unzip_assets()

    {%{title: title, pages: pages}, assets}
  end

  defp chapter({%Manual.ChapterModel{title: title}, _chapter_index}, _task_index),
    do: {%{title: title, pages: []}, []}

  defp page(
         {%Manual.PageModel{title: title, text: text, image: url}, page_index},
         task_index,
         chapter_index
       ) do
    {image, assets} =
      asset(url, "instruction-step-#{task_index}-#{chapter_index}-#{page_index}")

    {%{title: title, description: text, image: image}, assets}
  end

  defp sort_by_step(records), do: Enum.sort_by(records, &step_order/1)

  defp step_order(%{userflow_step: %{order: order}}) when is_integer(order), do: order
  defp step_order(_record), do: 0

  defp asset(url, _name) when url in [nil, ""], do: {nil, []}

  defp asset(url, name) when is_binary(url) do
    path = "assets/" <> name <> extname(url)
    {path, [%{path: path, url: url}]}
  end

  defp extname(url), do: url |> URI.parse() |> Map.get(:path) |> to_string() |> Path.extname()

  defp unzip_assets(pairs) do
    {values, assets} = Enum.unzip(pairs)
    {values, List.flatten(assets)}
  end
end
