defmodule Frameworks.E2E.Controller do
  @moduledoc """
  API endpoint for E2E test fixture setup.

  Creates test users and assignments needed for E2E tests.
  Only available when the :e2e feature is enabled via ENABLED_APP_FEATURES.

  POST /api/e2e/setup
  Requires authenticated service account session.

  Returns:
  {
    "researcher_email": "e2e-researcher@eyra.co",
    "researcher_password": "...",
    "participant_email": "e2e-participant@eyra.co",
    "participant_password": "...",
    "donate_assignment_path": "/a/xyz123"
  }
  """
  use CoreWeb, {:controller, [formats: [:json]]}
  use Core.FeatureFlags

  require Logger

  alias Core.Repo
  alias Systems.Account
  alias Systems.Affiliate
  alias Systems.Assignment
  alias Systems.Feldspar
  alias Systems.Storage

  @service_email "e2e@eyra.service"
  @service_password "E2EServicePassword123!"
  @researcher_email "e2e-researcher@eyra.co"
  @participant_email "e2e-participant@eyra.co"
  @e2e_password "E2ETestPassword123!"

  # Feldspar app release for E2E testing
  @feldspar_release_url "https://github.com/eyra/feldspar/releases/download/2026-02-25_5_milestone-6/feldspar_milestone-6_2026-02-25_5.zip"
  @feldspar_filename "feldspar_e2e.zip"

  @doc """
  Bootstrap endpoint - creates the E2E service user.
  No authentication required, but only works when :e2e feature is enabled.
  Call this once before running E2E tests.
  """
  def bootstrap(conn, _params) do
    if feature_enabled?(:e2e) do
      service_user = get_or_create_service_user()

      json(conn, %{
        service_email: service_user.email,
        service_password: @service_password,
        message:
          "Service user ready. Use /api/service/login to authenticate, then call /api/e2e/setup"
      })
    else
      conn
      |> put_status(403)
      |> json(%{error: "E2E bootstrap not available (enable :e2e feature)"})
    end
  end

  def setup(conn, _params) do
    if feature_enabled?(:e2e) do
      case setup_fixtures() do
        {:ok, fixtures} ->
          json(conn, fixtures)

        {:error, reason} ->
          conn
          |> put_status(500)
          |> json(%{error: "Failed to setup fixtures: #{inspect(reason)}"})
      end
    else
      conn
      |> put_status(403)
      |> json(%{error: "E2E setup not available (enable :e2e feature)"})
    end
  end

  defp setup_fixtures do
    # No transaction needed - all operations are idempotent (get_or_create)
    try do
      researcher = get_or_create_researcher()
      participant = get_or_create_participant()
      assignment = get_or_create_donate_assignment(researcher)

      {:ok,
       %{
         researcher_email: researcher.email,
         researcher_password: @e2e_password,
         participant_email: participant.email,
         participant_password: @e2e_password,
         donate_assignment_path: assignment_path(assignment)
       }}
    rescue
      e -> {:error, Exception.message(e)}
    end
  end

  defp get_or_create_service_user do
    case Account.Public.get_user_by_email(@service_email) do
      nil -> create_service_user()
      user -> user
    end
  end

  defp create_service_user do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    Core.Factories.insert!(:member, %{
      email: @service_email,
      password: @service_password,
      confirmed_at: now
    })
  end

  defp get_or_create_researcher do
    case Account.Public.get_user_by_email(@researcher_email) do
      nil -> create_researcher()
      user -> user
    end
  end

  defp create_researcher do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    Core.Factories.insert!(:member, %{
      email: @researcher_email,
      password: @e2e_password,
      creator: true,
      confirmed_at: now,
      verified_at: now
    })
  end

  defp get_or_create_participant do
    case Account.Public.get_user_by_email(@participant_email) do
      nil -> create_participant()
      user -> user
    end
  end

  defp create_participant do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    Core.Factories.insert!(:member, %{
      email: @participant_email,
      password: @e2e_password,
      creator: false,
      confirmed_at: now
    })
  end

  defp get_or_create_donate_assignment(researcher) do
    # Look for existing E2E assignment by checking for a specific title pattern
    case find_e2e_assignment() do
      nil ->
        create_donate_assignment(researcher)

      assignment ->
        # Ensure assignment has affiliate (may be missing from older fixtures)
        ensure_affiliate(assignment)
    end
  end

  defp ensure_affiliate(%{affiliate_id: nil} = assignment) do
    affiliate = Core.Factories.insert!(:affiliate, %{})
    ensure_fields(assignment, %{affiliate_id: affiliate.id})
  end

  defp ensure_affiliate(assignment) do
    ensure_fields(assignment, %{})
  end

  defp ensure_fields(assignment, updates) do
    # Ensure special is set for data donation
    updates =
      if assignment.special == nil do
        Map.put(updates, :special, :data_donation)
      else
        updates
      end

    # Update assignment if needed
    assignment =
      if updates == %{} do
        assignment
      else
        assignment
        |> Ecto.Changeset.change(updates)
        |> Repo.update!()
      end

    # Ensure Feldspar tool has valid archive_ref
    assignment = ensure_feldspar_app(assignment)

    # Ensure storage endpoint is configured
    assignment = ensure_storage(assignment)

    assignment |> Repo.preload(Assignment.Model.preload_graph(:down))
  end

  defp ensure_feldspar_app(assignment) do
    assignment = Repo.preload(assignment, workflow: [items: [tool_ref: :feldspar_tool]])

    case assignment do
      %{workflow: %{items: [%{tool_ref: %{feldspar_tool: %{archive_ref: ref} = tool}} | _]}}
      when is_nil(ref) or ref == "" or ref == "e2e-test-app" ->
        # Feldspar tool needs a real archive_ref
        archive_ref = get_or_download_feldspar_app()

        tool
        |> Ecto.Changeset.change(%{archive_ref: archive_ref, archive_name: @feldspar_filename})
        |> Repo.update!()

        Logger.info("[E2E] Updated Feldspar tool #{tool.id} with archive_ref: #{archive_ref}")
        assignment

      _ ->
        # Already has valid archive_ref
        assignment
    end
  end

  defp ensure_storage(assignment) do
    # Check if assignment already has a project item (which means storage is configured)
    import Ecto.Query

    has_project_item =
      from(pi in Systems.Project.ItemModel,
        where: pi.assignment_id == ^assignment.id
      )
      |> Repo.exists?()

    unless has_project_item do
      setup_storage_for_assignment(assignment)
    end

    assignment
  end

  defp find_e2e_assignment do
    import Ecto.Query

    from(a in Assignment.Model,
      join: i in assoc(a, :info),
      where: like(i.title, "E2E Test%"),
      limit: 1
    )
    |> Repo.one()
  end

  defp create_donate_assignment(researcher) do
    # Create auth nodes
    auth_node = Core.Factories.insert!(:auth_node)
    tool_auth_node = Core.Factories.insert!(:auth_node, %{parent: auth_node})

    # Create affiliate for participant access via /a/ URL
    affiliate = Core.Factories.insert!(:affiliate, %{})

    # Download and store Feldspar app
    archive_ref = get_or_download_feldspar_app()

    # Create Feldspar tool with the stored app
    feldspar_tool =
      Core.Factories.insert!(:feldspar_tool, %{
        archive_ref: archive_ref,
        archive_name: @feldspar_filename,
        auth_node: tool_auth_node
      })

    # Create workflow with tool
    tool_ref = Core.Factories.insert!(:tool_ref, %{feldspar_tool: feldspar_tool})
    workflow = Core.Factories.insert!(:workflow, %{})

    Core.Factories.insert!(:workflow_item, %{
      workflow: workflow,
      tool_ref: tool_ref,
      title: "TikTok Data Donation",
      position: 0
    })

    # Create assignment info
    info =
      Core.Factories.insert!(:assignment_info, %{
        title: "E2E Test Data Donation",
        subject_count: 100,
        duration: "10",
        language: :en,
        devices: [:desktop]
      })

    # Create crew and assignment
    crew = Core.Factories.insert!(:crew)

    assignment =
      Core.Factories.insert!(:assignment, %{
        info: info,
        affiliate: affiliate,
        workflow: workflow,
        crew: crew,
        auth_node: auth_node,
        special: :data_donation,
        status: :online
      })

    # Grant researcher owner role
    Core.Authorization.assign_role(researcher, assignment, :owner)

    # Create project structure with storage endpoint for data donation
    setup_storage_for_assignment(assignment)

    assignment |> Repo.preload(Assignment.Model.preload_graph(:down))
  end

  defp setup_storage_for_assignment(assignment) do
    # Create project node
    project_node =
      Core.Factories.insert!(:project_node, %{
        name: "e2e_test_node",
        project_path: []
      })

    # Create storage endpoint (builtin for local dev)
    storage_endpoint =
      Storage.Public.prepare_endpoint(:builtin, %{key: "e2e_test_storage"})
      |> Repo.insert!()

    # Link assignment to project node
    Core.Factories.insert!(:project_item, %{
      name: "e2e_assignment_item",
      project_path: [],
      node_id: project_node.id,
      assignment_id: assignment.id
    })

    # Link storage endpoint to same project node
    Core.Factories.insert!(:project_item, %{
      name: "e2e_storage_item",
      project_path: [],
      node_id: project_node.id,
      storage_endpoint_id: storage_endpoint.id
    })

    Logger.info("[E2E] Created storage endpoint for assignment #{assignment.id}")
  end

  defp assignment_path(%Assignment.Model{} = assignment) do
    Affiliate.Public.url_for_resource(assignment)
    |> URI.parse()
    |> Map.get(:path)
  end

  # Feldspar app download and storage

  defp get_or_download_feldspar_app do
    # Check if we already have an E2E Feldspar app stored
    case find_e2e_feldspar_tool() do
      %{archive_ref: archive_ref} when is_binary(archive_ref) and archive_ref != "" ->
        Logger.info("[E2E] Reusing existing Feldspar app: #{archive_ref}")
        archive_ref

      _ ->
        Logger.info("[E2E] Downloading Feldspar app from GitHub...")
        download_and_store_feldspar_app()
    end
  end

  defp find_e2e_feldspar_tool do
    import Ecto.Query

    from(t in Feldspar.ToolModel,
      where: t.archive_name == ^@feldspar_filename,
      limit: 1
    )
    |> Repo.one()
  end

  defp download_and_store_feldspar_app do
    # Download zip from GitHub
    temp_path = Path.join(System.tmp_dir!(), @feldspar_filename)

    case download_file(@feldspar_release_url, temp_path) do
      :ok ->
        # Store using Feldspar storage backend
        folder = Feldspar.Public.store(temp_path, @feldspar_filename)
        archive_ref = Feldspar.Public.get_public_url(folder)

        # Clean up temp file
        File.rm(temp_path)

        Logger.info("[E2E] Feldspar app stored at: #{archive_ref}")
        archive_ref

      {:error, reason} ->
        File.rm(temp_path)
        raise "Failed to download Feldspar app: #{inspect(reason)}"
    end
  end

  defp download_file(url, dest_path) do
    Logger.info("[E2E] Downloading #{url}")

    case HTTPoison.get(url, [], follow_redirect: true, max_redirect: 5) do
      {:ok, %{status_code: 200, body: body}} ->
        File.write!(dest_path, body)
        :ok

      {:ok, %{status_code: status}} ->
        {:error, "HTTP #{status}"}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
