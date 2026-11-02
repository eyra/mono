defmodule Next.SaaS do
  @moduledoc "Next, Eyra's SaaS on Mica."
  use Core.SaaS
  use Core.FeatureFlags

  @impl true
  def systems do
    Core.Systems.all() ++
      [
        Next.WellKnown.System,
        Next.Account.System,
        Next.E2E.System,
        Next.Panl.System,
        Systems.Announcement.System,
        Systems.Graphite.System,
        Systems.Onyx.System,
        Systems.Student.System,
        Systems.Zircon.System,
        Systems.Paper.System,
        Systems.Probe.System
      ]
  end

  # On Fly and AWS, ENABLED_APP_FEATURES turns more flags on.
  @impl true
  def feature_flags do
    [
      announcements: false,
      surfconext_sign_in: false,
      centerdata_sign_in: false,
      member_google_sign_in: true,
      password_sign_in: true,
      debug_expire_force: false,
      leaderboard: true,
      panl: true,
      panl_post_launch: false,
      opp_phase_3: false,
      onyx: false,
      otp: false,
      probe: false,
      e2e: false
    ]
  end

  @impl true
  def start_pages, do: Next.StartPages

  @impl true
  def menu_items, do: Next.Menu.Items

  @impl true
  def menu_builder(:workspace), do: Next.Layouts.Workspace.MenuBuilder
  def menu_builder(:website), do: Next.Layouts.Website.MenuBuilder
  def menu_builder(:stripped), do: Next.Layouts.Stripped.MenuBuilder

  @impl true
  def title, do: "Next"

  @impl true
  def signed_in_page(:creator), do: "/project"
  def signed_in_page(:member), do: "/"

  @impl true
  def sign_in_page do
    if feature_enabled?(:otp), do: "/user/auth/identify", else: "/user/signin"
  end

  @impl true
  def member_sign_in_page(return_to) do
    if feature_enabled?(:otp),
      do: CoreWeb.ReturnTo.append("/user/auth/identify/participant", return_to),
      else: "/user/signin"
  end
end
