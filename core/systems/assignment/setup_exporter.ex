defmodule Systems.Assignment.SetupExporter do
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
  @max_asset_bytes Application.compile_env!(:core, [CoreWeb.FileUploader, :max_file_size])
  @skipped_key :setup_export_skipped
  @metadata_name "next-metadata.json"
  @warnings_name "export-warnings.json"
  @ro_crate_name "ro-crate-metadata.json"
  @file_descriptions %{
    @metadata_name =>
      "Serialized study setup: branding, information pages, consent and workflow tasks.",
    @warnings_name => "Assets that could not be included in this export."
  }

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
  Packmatic entries for the whole export: the metadata document, one entry per
  configured asset, the RO-Crate description of the package and a closing
  `export-warnings.json`, all nested under `folder`. `name` is the study name
  written into the metadata; `folder` is the slug used for both the folder and
  the zip file.

  The warnings document only materializes when an asset was actually skipped;
  a clean export carries no `export-warnings.json`.
  """
  def entries(%Assignment.Model{} = assignment, name, folder) do
    {metadata, assets} = metadata(assignment, name)

    [metadata_entry(metadata, folder)] ++
      Enum.map(assets, &asset_entry(&1, folder)) ++
      [ro_crate_entry(metadata, assets, folder), warnings_entry(folder)]
  end

  @doc """
  Registers an asset that Packmatic could not fetch, so `export-warnings.json`
  can report it. Packmatic consumes the stream in the process that serves the
  request, so the accumulated list rides along in the process dictionary.

  Returns `:ignore` for the warnings document itself: a clean export drops that
  entry, which Packmatic reports as a failure like any other.
  """
  def record_skipped(path, reason) do
    if warnings_document?(path) do
      :ignore
    else
      Process.put(@skipped_key, skipped() ++ [%{path: path, reason: inspect(reason)}])
      :ok
    end
  end

  defp warnings_document?(path), do: String.ends_with?(path, "/" <> @warnings_name)

  defp skipped, do: Process.get(@skipped_key, [])

  defp warnings_entry(folder) do
    [
      source: {:dynamic, &warnings_source/0},
      path: "#{folder}/#{@warnings_name}",
      timestamp: DateTime.utc_now()
    ]
  end

  defp warnings_source do
    case skipped() do
      [] -> {:error, :no_warnings}
      skipped -> {:ok, {:stream, [Jason.encode!(%{skipped: skipped}, pretty: true)]}}
    end
  end

  defp ro_crate_entry(metadata, assets, folder) do
    [
      source: {:dynamic, fn -> ro_crate_source(metadata, assets, folder) end},
      path: "#{folder}/#{@ro_crate_name}",
      timestamp: DateTime.utc_now()
    ]
  end

  defp ro_crate_source(metadata, assets, folder) do
    {:ok, {:stream, [Jason.encode!(ro_crate(metadata, assets, folder), pretty: true)]}}
  end

  @doc """
  RO-Crate 1.1 description of the exported package: the metadata file
  descriptor, the root dataset and one file entity per bundled document.

  Paths stay relative to the export folder, which is the RO-Crate root, so the
  crate describes the same tree the zip already contains. Assets that Packmatic
  could not fetch are left out, as is the warnings document when there is
  nothing to warn about, which is why this document is resolved after every
  asset entry.
  """
  def ro_crate(metadata, assets, folder) do
    parts = [@metadata_name] ++ exported_asset_paths(assets, folder) ++ warnings_parts()

    %{
      "@context" => "https://w3id.org/ro/crate/1.1/context",
      "@graph" =>
        [ro_crate_descriptor(), ro_crate_root(metadata, parts)] ++
          Enum.map(parts, &ro_crate_file/1)
    }
  end

  defp exported_asset_paths(assets, folder) do
    skipped = skipped() |> Enum.map(& &1.path) |> MapSet.new()

    assets
    |> Enum.map(& &1.path)
    |> Enum.uniq()
    |> Enum.reject(&MapSet.member?(skipped, "#{folder}/#{&1}"))
  end

  defp warnings_parts do
    case skipped() do
      [] -> []
      _skipped -> [@warnings_name]
    end
  end

  defp ro_crate_descriptor do
    %{
      "@id" => @ro_crate_name,
      "@type" => "CreativeWork",
      "conformsTo" => %{"@id" => "https://w3id.org/ro/crate/1.1"},
      "about" => %{"@id" => "./"}
    }
  end

  defp ro_crate_root(
         %{
           assignment: %{id: id, name: name},
           language: language,
           branding: %{subtitle: subtitle}
         },
         parts
       ) do
    %{
      "@id" => "./",
      "@type" => "Dataset",
      "name" => name,
      "description" => ro_crate_description(subtitle, name),
      "datePublished" => DateTime.utc_now() |> DateTime.to_iso8601(),
      "identifier" => "next-assignment-#{id}",
      "hasPart" => Enum.map(parts, &%{"@id" => &1})
    }
    |> put_language(language)
  end

  defp ro_crate_description(subtitle, _name) when is_binary(subtitle) and subtitle != "",
    do: subtitle

  defp ro_crate_description(_subtitle, name), do: "Exported study setup of #{name}."

  defp put_language(root, language) when is_atom(language) and not is_nil(language),
    do: Map.put(root, "inLanguage", Atom.to_string(language))

  defp put_language(root, language) when is_binary(language) and language != "",
    do: Map.put(root, "inLanguage", language)

  defp put_language(root, _language), do: root

  defp ro_crate_file(path) do
    %{
      "@id" => path,
      "@type" => "File",
      "name" => Path.basename(path),
      "encodingFormat" => MIME.from_path(path)
    }
    |> put_file_description(path)
  end

  defp put_file_description(file, path) do
    case Map.fetch(@file_descriptions, path) do
      {:ok, description} -> Map.put(file, "description", description)
      :error -> file
    end
  end

  defp metadata_entry(metadata, folder) do
    [
      source: {:stream, [Jason.encode!(metadata, pretty: true)]},
      path: "#{folder}/#{@metadata_name}",
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
         {%Manual.PageModel{title: title, text: text, image: image}, page_index},
         task_index,
         chapter_index
       ) do
    {image, assets} =
      asset(image_url(image), "instruction-step-#{task_index}-#{chapter_index}-#{page_index}")

    {%{title: title, description: text, image: image}, assets}
  end

  defp image_url(image) do
    case Core.ImageHelpers.decode_image_info(image) do
      %{url: url} -> url
      nil -> nil
    end
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
