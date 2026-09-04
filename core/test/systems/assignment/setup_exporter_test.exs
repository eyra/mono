defmodule Systems.Assignment.SetupExporterTest do
  use Core.DataCase

  alias Core.Factories
  alias Systems.Assignment
  alias Systems.Manual

  defp load(assignment),
    do: Repo.preload(assignment, Assignment.SetupExporter.preload_graph(), force: true)

  defp metadata(assignment, name \\ "test study"),
    do: assignment |> load() |> Assignment.SetupExporter.metadata(name)

  defp asset_paths(map) do
    map
    |> Jason.encode!()
    |> then(&Regex.scan(~r|"(assets/[^"]+)"|, &1))
    |> Enum.map(&Enum.at(&1, 1))
    |> Enum.sort()
  end

  describe "metadata/2 - asset invariant" do
    test "every assets/ path in the metadata has a matching asset entry, and vice versa" do
      info =
        Factories.insert!(:assignment_info, %{
          title: "Title",
          logo_url: "https://example.com/brand/logo.png"
        })

      privacy_doc =
        Factories.insert!(:content_file, %{name: "p.pdf", ref: "https://x.test/p.pdf"})

      assignment =
        Factories.insert!(:assignment, %{info: info, privacy_doc: privacy_doc})

      {map, assets} = metadata(assignment)

      assert asset_paths(map) == assets |> Enum.map(& &1.path) |> Enum.sort()
      assert "assets/logo.png" in asset_paths(map)
      assert "assets/privacy-statement.pdf" in asset_paths(map)
    end
  end

  describe "entries/3" do
    test "produces a manifest Packmatic accepts when the study has assets" do
      info =
        Factories.insert!(:assignment_info, %{
          title: "Title",
          logo_url: "https://example.com/brand/logo.png"
        })

      privacy_doc =
        Factories.insert!(:content_file, %{name: "p.pdf", ref: "https://x.test/p.pdf"})

      assignment = Factories.insert!(:assignment, %{info: info, privacy_doc: privacy_doc})

      entries = assignment |> load() |> Assignment.SetupExporter.entries("study", "study_2026")

      assert %{valid?: true, errors: []} = Packmatic.Manifest.create(entries)
      assert length(entries) == 4
    end

    test "produces a manifest Packmatic accepts when the study has no assets" do
      assignment = Factories.insert!(:assignment, %{info: nil})

      entries = assignment |> load() |> Assignment.SetupExporter.entries("study", "study_2026")

      assert %{valid?: true, errors: []} = Packmatic.Manifest.create(entries)
    end

    test "reads a locally stored asset from disk instead of over HTTP" do
      logo_url = Systems.Content.LocalFS.get_public_url("/tmp/abc_logo.png")
      info = Factories.insert!(:assignment_info, %{logo_url: logo_url})
      assignment = Factories.insert!(:assignment, %{info: info})

      entries = assignment |> load() |> Assignment.SetupExporter.entries("study", "study_2026")
      entry = Enum.find(entries, &(&1[:path] == "study_2026/assets/logo.png"))

      assert {:file, path} = entry[:source]
      assert Path.basename(path) == "abc_logo.png"
    end

    test "nests every entry under the folder" do
      assignment = Factories.insert!(:assignment, %{info: nil})

      entries = assignment |> load() |> Assignment.SetupExporter.entries("study", "study_2026")

      assert Enum.all?(entries, &String.starts_with?(&1[:path], "study_2026/"))
    end

    test "reports skipped assets in the warnings entry, which resolves last" do
      assignment = Factories.insert!(:assignment, %{info: nil})

      entries = assignment |> load() |> Assignment.SetupExporter.entries("study", "study_2026")
      entry = List.last(entries)

      assert entry[:path] == "study_2026/export-warnings.json"

      :ok = Assignment.SetupExporter.record_skipped("study_2026/assets/logo.png", :timeout)

      assert {:ok, {:stream, [json]}} = entry[:source] |> elem(1) |> apply([])

      assert %{"skipped" => [%{"path" => "study_2026/assets/logo.png", "reason" => ":timeout"}]} =
               Jason.decode!(json)
    end
  end

  describe "metadata/2 - unconfigured study" do
    test "emits every key as null and no assets" do
      assignment = Factories.insert!(:assignment, %{info: nil})

      {map, assets} = metadata(assignment)

      assert assets == []
      assert map.branding == %{title: nil, subtitle: nil, logo: nil, header_image: nil}
      assert map.about == nil
      assert map.consent == nil
      assert map.helpdesk == nil
      assert map.privacy_statement_pdf == nil
      assert map.format_version == 1
    end

    test "a nil image_id emits no header image" do
      info = Factories.insert!(:assignment_info, %{image_id: nil})
      assignment = Factories.insert!(:assignment, %{info: info})

      {map, _assets} = metadata(assignment)

      assert map.branding.header_image == nil
    end

    test "a header image is referenced by its remote URL, not bundled" do
      image_id =
        URI.encode_query(%{
          "raw_url" => "https://images.unsplash.com/photo-123",
          "username" => "someone",
          "name" => "Some One",
          "blur_hash" => "abc"
        })

      info = Factories.insert!(:assignment_info, %{image_id: image_id})
      assignment = Factories.insert!(:assignment, %{info: info})

      {%{branding: %{header_image: header_image}}, assets} = metadata(assignment)

      assert String.starts_with?(header_image, "https://images.unsplash.com/photo-123")
      assert assets == []
    end
  end

  describe "metadata/2 - workflow" do
    test "preserves task order regardless of insertion order" do
      assignment = Assignment.Factories.create_assignment_with_multiple_tasks()

      {%{workflow: %{tasks: tasks}}, _assets} = metadata(assignment)

      assert Enum.map(tasks, & &1.title) == ["Task 1", "Task 2"]
    end

    test "serializes an alliance tool as a questionnaire task" do
      assignment = Assignment.Factories.create_assignment_with_multiple_tasks()

      {%{workflow: %{tasks: [task | _]}}, _assets} = metadata(assignment)

      assert %{type: "questionnaire", link: "https://eyra.co/alliance/123"} = task
    end

    test "serializes a feldspar tool as a data donation task without bundling the app" do
      assignment = Assignment.Factories.create_assignment_with_feldspar_tool()

      {%{workflow: %{tasks: [task]}}, assets} = metadata(assignment)

      assert %{type: "data_donation", title: "Feldspar Task"} = task
      assert assets == []
    end

    test "a tool type without an explicit clause still produces a task" do
      auth_node = Factories.insert!(:auth_node)
      tool = Factories.insert!(:graphite_tool, %{auth_node: auth_node})
      tool_ref = Factories.insert!(:tool_ref, %{graphite_tool: tool})
      workflow = Factories.insert!(:workflow, %{})

      Factories.insert!(:workflow_item, %{
        workflow: workflow,
        tool_ref: tool_ref,
        title: "Benchmark",
        position: 0
      })

      assignment = Factories.insert!(:assignment, %{workflow: workflow})

      {%{workflow: %{tasks: [task]}}, _assets} = metadata(assignment)

      assert %{type: "graphite", title: "Benchmark"} = task
    end

    test "bundles an uploaded manual page image stored as encoded image info" do
      image =
        Jason.encode!(%{
          url: "https://x.test/uploads/step.png",
          width: 100,
          height: 50,
          blur_hash: "abc"
        })

      assignment = assignment_with_manual_page(image)

      {%{workflow: %{tasks: [task]}}, assets} = metadata(assignment)

      assert %{chapters: [%{pages: [%{image: "assets/instruction-step-1-1-1.png"}]}]} = task

      assert [
               %{
                 path: "assets/instruction-step-1-1-1.png",
                 url: "https://x.test/uploads/step.png"
               }
             ] =
               assets
    end

    test "bundles a manual page image stored as a plain url" do
      assignment = assignment_with_manual_page("https://x.test/uploads/step.jpg")

      {_map, assets} = metadata(assignment)

      assert [%{url: "https://x.test/uploads/step.jpg"}] = assets
    end
  end

  defp assignment_with_manual_page(image) do
    manual_tool = Manual.Factories.create_manual_tool(1, 1, Factories.insert!(:auth_node))
    %{chapters: [%{pages: [page]}]} = manual_tool.manual
    Repo.update!(Ecto.Changeset.change(page, image: image))

    tool_ref = Factories.insert!(:tool_ref, %{manual_tool: manual_tool})
    workflow = Factories.insert!(:workflow, %{})

    Factories.insert!(:workflow_item, %{
      workflow: workflow,
      tool_ref: tool_ref,
      title: "Manual",
      position: 0
    })

    Factories.insert!(:assignment, %{workflow: workflow})
  end
end
