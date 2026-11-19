defmodule MicaSaas.Systems.Assignment.SetupExporterTest do
  use Mica.DataCase

  alias Mica.Factories
  alias Systems.Account
  alias Systems.Assignment

  defp load(assignment),
    do: Repo.preload(assignment, Assignment.SetupExporter.preload_graph(), force: true)

  defp put_max_file_size(bytes) do
    original = Application.fetch_env!(:mica, MicaWeb.FileUploader)
    on_exit(fn -> Application.put_env(:mica, MicaWeb.FileUploader, original) end)
    Application.put_env(:mica, MicaWeb.FileUploader, Keyword.put(original, :max_file_size, bytes))
  end

  # A logo in our S3 content storage, served by the Bypass server.
  defp assignment_with_logo(%Bypass{port: port}) do
    use_s3_content("http://localhost:#{port}")

    info =
      Factories.insert!(:assignment_info, %{
        logo_url: "http://localhost:#{port}/content/logo.png"
      })

    Factories.insert!(:assignment, %{info: info})
  end

  defp export_files(assignment) do
    {:ok, stream} = assignment |> load() |> Assignment.SetupExporter.stream("study", "study_2026")
    {:ok, files} = stream |> Enum.to_list() |> IO.iodata_to_binary() |> :zip.extract([:memory])
    Map.new(files, fn {name, data} -> {to_string(name), data} end)
  end

  defp use_s3_content(public_url) do
    original = Application.fetch_env!(:mica, :content)
    on_exit(fn -> Application.put_env(:mica, :content, original) end)

    Application.put_env(:mica, :content,
      backend: Systems.Content.S3,
      public_url: public_url,
      prefix: "content"
    )
  end

  describe "entries/3" do
    test "skips a remote asset over the upload limit and reports it" do
      put_max_file_size(1_024)
      bypass = Bypass.open()

      Bypass.stub(bypass, "GET", "/content/logo.png", fn conn ->
        Plug.Conn.resp(conn, 200, :binary.copy("x", 4_096))
      end)

      files = bypass |> assignment_with_logo() |> export_files()

      refute Map.has_key?(files, "study_2026/assets/logo.png")

      assert %{"skipped" => [%{"path" => "study_2026/assets/logo.png", "reason" => reason}]} =
               Jason.decode!(files["study_2026/export-warnings.json"])

      assert reason =~ "too_large"
    end

    test "includes a remote asset within the upload limit" do
      put_max_file_size(4_096)
      bypass = Bypass.open()

      Bypass.expect_once(
        bypass,
        "GET",
        "/content/logo.png",
        &Plug.Conn.resp(&1, 200, :binary.copy("x", 4_096))
      )

      files = bypass |> assignment_with_logo() |> export_files()

      assert files["study_2026/assets/logo.png"] == :binary.copy("x", 4_096)
      refute Map.has_key?(files, "study_2026/export-warnings.json")
    end

    test "includes an empty remote asset" do
      bypass = Bypass.open()
      Bypass.expect_once(bypass, "GET", "/content/logo.png", &Plug.Conn.resp(&1, 200, ""))

      files = bypass |> assignment_with_logo() |> export_files()

      assert files["study_2026/assets/logo.png"] == ""
      refute Map.has_key?(files, "study_2026/export-warnings.json")
    end

    test "skips a remote asset that answers with an empty error response" do
      bypass = Bypass.open()
      Bypass.expect_once(bypass, "GET", "/content/logo.png", &Plug.Conn.resp(&1, 404, ""))

      files = bypass |> assignment_with_logo() |> export_files()

      refute Map.has_key?(files, "study_2026/assets/logo.png")

      assert %{"skipped" => [%{"path" => "study_2026/assets/logo.png", "reason" => reason}]} =
               Jason.decode!(files["study_2026/export-warnings.json"])

      assert reason =~ "404"
    end

    test "does not follow a redirect from a remote asset" do
      bypass = Bypass.open()

      Bypass.expect_once(bypass, "GET", "/content/logo.png", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("location", "http://localhost:#{bypass.port}/elsewhere.png")
        |> Plug.Conn.resp(302, "")
      end)

      files = bypass |> assignment_with_logo() |> export_files()

      refute Map.has_key?(files, "study_2026/assets/logo.png")

      assert %{"skipped" => [%{"path" => "study_2026/assets/logo.png", "reason" => reason}]} =
               Jason.decode!(files["study_2026/export-warnings.json"])

      assert reason =~ "302"
    end

    test "lists an external privacy statement in export-warnings.json and leaves it out of the zip" do
      privacy_doc =
        Factories.insert!(:content_file, %{name: "p.pdf", ref: "https://example.com/p.pdf"})

      assignment = Factories.insert!(:assignment, %{info: nil, privacy_doc: privacy_doc})

      {:ok, stream} =
        assignment |> load() |> Assignment.SetupExporter.stream("study", "study_2026")

      {:ok, files} = stream |> Enum.to_list() |> IO.iodata_to_binary() |> :zip.unzip([:memory])
      files = Map.new(files, fn {name, content} -> {to_string(name), content} end)

      refute Map.has_key?(files, "study_2026/assets/privacy-statement.pdf")

      assert %{
               "skipped" => [
                 %{
                   "path" => "study_2026/assets/privacy-statement.pdf",
                   "reason" => ":external_url"
                 }
               ]
             } = Jason.decode!(files["study_2026/export-warnings.json"])
    end

    test "lists a skipped external asset in export-warnings.json and leaves it out of the zip" do
      info = Factories.insert!(:assignment_info, %{logo_url: "http://127.0.0.1:1/logo.png"})
      assignment = Factories.insert!(:assignment, %{info: info})

      {:ok, stream} =
        assignment |> load() |> Assignment.SetupExporter.stream("study", "study_2026")

      {:ok, files} = stream |> Enum.to_list() |> IO.iodata_to_binary() |> :zip.unzip([:memory])
      files = Map.new(files, fn {name, content} -> {to_string(name), content} end)

      refute Map.has_key?(files, "study_2026/assets/logo.png")

      assert %{
               "skipped" => [
                 %{"path" => "study_2026/assets/logo.png", "reason" => ":external_url"}
               ]
             } =
               Jason.decode!(files["study_2026/export-warnings.json"])
    end
  end

  describe "entries/3 - ro-crate" do
    test "describes the package with a metadata descriptor and a root dataset" do
      info =
        Factories.insert!(:assignment_info, %{
          title: "Title",
          subtitle: "Subtitle",
          language: :nl,
          logo_url: "https://example.com/brand/logo.png"
        })

      assignment = Factories.insert!(:assignment, %{info: info})

      crate = crate(assignment, "My study")

      assert crate["@context"] == "https://w3id.org/ro/crate/1.1/context"

      assert %{
               "@type" => "CreativeWork",
               "conformsTo" => %{"@id" => "https://w3id.org/ro/crate/1.1"},
               "about" => %{"@id" => "./"}
             } = entity(crate, "ro-crate-metadata.json")

      assert %{
               "@type" => "Dataset",
               "name" => "My study",
               "description" => "Exported study setup of My study.",
               "inLanguage" => "nl",
               "identifier" => identifier,
               "datePublished" => published
             } = entity(crate, "./")

      assert identifier == "next-assignment-#{assignment.id}"
      assert {:ok, _datetime, _offset} = DateTime.from_iso8601(published)
    end

    test "lists the metadata document and every exported asset" do
      info =
        Factories.insert!(:assignment_info, %{
          title: "Title",
          logo_url: "https://example.com/brand/logo.png"
        })

      privacy_doc =
        Factories.insert!(:content_file, %{name: "p.pdf", ref: "https://x.test/p.pdf"})

      assignment = Factories.insert!(:assignment, %{info: info, privacy_doc: privacy_doc})

      crate = crate(assignment)

      assert parts(crate) == [
               "next-metadata.json",
               "assets/logo.png",
               "assets/privacy-statement.pdf"
             ]

      assert Enum.all?(parts(crate), &(entity(crate, &1)["@type"] == "File"))
      assert entity(crate, "assets/logo.png")["encodingFormat"] == "image/png"
      assert entity(crate, "assets/privacy-statement.pdf")["encodingFormat"] == "application/pdf"
      assert entity(crate, "next-metadata.json")["encodingFormat"] == "application/json"
    end

    test "omits the warnings document when nothing was skipped" do
      assignment = Factories.insert!(:assignment, %{info: nil})

      crate = crate(assignment)

      refute "export-warnings.json" in parts(crate)
      assert entity(crate, "export-warnings.json") == nil
    end

    test "leaves assets that could not be fetched out of the crate" do
      info =
        Factories.insert!(:assignment_info, %{
          title: "Title",
          logo_url: "https://example.com/brand/logo.png"
        })

      assignment = Factories.insert!(:assignment, %{info: info})
      entries = entries(assignment)

      :ok = Assignment.SetupExporter.record_skipped("study_2026/assets/logo.png", :timeout)

      crate = resolve_crate(entries)

      refute "assets/logo.png" in parts(crate)
      assert entity(crate, "assets/logo.png") == nil
      assert parts(crate) == ["next-metadata.json", "export-warnings.json"]
    end

    test "credits every owner as author and names the licence and publisher" do
      assignment = Factories.insert!(:assignment, %{info: nil})

      owner =
        Factories.insert!(:member, %{
          profile: %Account.UserProfileModel{fullname: "Ada Lovelace"}
        })

      :ok = Mica.Authorization.assign_role(owner, assignment, :owner)

      crate = crate(assignment)
      root = entity(crate, "./")

      assert root["author"] == [%{"@id" => "#author-1"}]
      assert entity(crate, "#author-1")["name"] == "Ada Lovelace"
      assert entity(crate, "#author-1")["@type"] == "Person"

      assert root["license"] == %{
               "@id" => "https://creativecommons.org/licenses/by/4.0/"
             }

      assert entity(crate, "https://creativecommons.org/licenses/by/4.0/")["name"] ==
               "Creative Commons Attribution 4.0 International"

      assert entity(crate, "https://creativecommons.org/licenses/by/4.0/")["description"] =~
               "third-party content that is not covered by the selected license"

      assert %{"@id" => publisher_id} = root["publisher"]
      assert entity(crate, publisher_id)["@type"] == "Organization"
    end

    test "reaches each author through a contact point carrying their email" do
      assignment = Factories.insert!(:assignment, %{info: nil})
      owner = Factories.insert!(:member, %{email: "ada@example.com"})

      :ok = Mica.Authorization.assign_role(owner, assignment, :owner)

      crate = crate(assignment)

      assert entity(crate, "#author-1")["contactPoint"] == %{"@id" => "mailto:ada@example.com"}

      assert entity(crate, "mailto:ada@example.com") == %{
               "@id" => "mailto:ada@example.com",
               "@type" => "ContactPoint",
               "email" => "ada@example.com"
             }
    end

    test "omits author when the study has no owner" do
      assignment = Factories.insert!(:assignment, %{info: nil})

      refute Map.has_key?(entity(crate(assignment), "./"), "author")
    end

    test "describes an unconfigured study with a generated description" do
      assignment = Factories.insert!(:assignment, %{info: nil})

      crate = crate(assignment, "My study")

      assert entity(crate, "./")["description"] == "Exported study setup of My study."
      assert entity(crate, "./")["inLanguage"] == "en"
      assert parts(crate) == ["next-metadata.json"]
    end
  end

  defp entries(assignment, name \\ "study"),
    do: assignment |> load() |> Assignment.SetupExporter.entries(name, "study_2026")

  defp crate(assignment, name \\ "study"), do: assignment |> entries(name) |> resolve_crate()

  defp resolve_crate(entries) do
    entry = Enum.find(entries, &(&1[:path] == "study_2026/ro-crate-metadata.json"))
    {:ok, {:stream, [json]}} = entry[:source] |> elem(1) |> apply([])
    Jason.decode!(json)
  end

  defp entity(%{"@graph" => graph}, id), do: Enum.find(graph, &(&1["@id"] == id))

  defp parts(crate), do: crate |> entity("./") |> Map.fetch!("hasPart") |> Enum.map(& &1["@id"])
end
