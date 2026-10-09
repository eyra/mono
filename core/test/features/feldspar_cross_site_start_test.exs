defmodule CoreWeb.Features.FeldsparCrossSiteStartTest do
  @moduledoc """
  Feldspar apps are served from another site in production (S3/Tigris), and the
  app container stays hidden until the app is initialized. The browser must keep
  rendering the hidden iframe, otherwise legacy apps never post the resize that
  makes Next send live-init.

  The page is visited on `localhost`; the app is served from `127.0.0.1`, which
  the browser treats as a different site.
  """
  use CoreWeb.FeatureCase

  alias Systems.Affiliate
  alias Systems.Assignment

  @upload_fixtures_path "test/systems/feldspar"

  setup %{app: app} do
    app_id = "#{app}_#{System.unique_integer([:positive])}"
    target_path = Path.join(Application.get_env(:core, :upload_path), app_id)

    File.mkdir_p!(target_path)
    File.cp_r!(Path.join([File.cwd!(), @upload_fixtures_path, app]), target_path)
    on_exit(fn -> File.rm_rf!(target_path) end)

    %{archive_ref: cross_site_url("/feldspar/apps/#{app_id}")}
  end

  @tag :feature
  @tag app: "mock_legacy_app"
  feature "a legacy app that only posts resize starts once", %{
    session: session,
    archive_ref: archive_ref
  } do
    session
    |> start_feldspar_task(archive_ref)
    |> assert_single_live_init()
  end

  @tag :feature
  @tag app: "mock_app_loaded_app"
  feature "an app that posts app-loaded starts once", %{
    session: session,
    archive_ref: archive_ref
  } do
    session
    |> start_feldspar_task(archive_ref)
    |> assert_single_live_init()
  end

  defp cross_site_url(path) do
    port = Application.fetch_env!(:core, CoreWeb.Endpoint) |> get_in([:http, :port])
    "http://127.0.0.1:#{port}#{path}"
  end

  defp start_feldspar_task(session, archive_ref) do
    assignment = Assignment.Factories.create_feldspar_assignment_with_affiliate(archive_ref)
    sqid = Affiliate.Sqids.encode!([0, assignment.id])

    session
    |> visit("/a/#{sqid}?p=cross_site_#{System.unique_integer([:positive])}")
    |> click(Query.css("[data-testid='feldspar-start'][phx-click='prepare_start']"))
    |> assert_has(Query.css("[data-testid='app-container']"))
  end

  defp assert_single_live_init(session) do
    session
    |> focus_frame(Query.css("[data-testid='app-container'] iframe"))
    |> assert_has(Query.css("[data-testid='live-init-count']", text: "1"))

    # The app grows after live-init, so Next receives further resizes; none may
    # start the app again.
    Process.sleep(500)

    session
    |> assert_has(Query.css("[data-testid='live-init-count']", text: "1"))
    |> focus_default_frame()
  end
end
