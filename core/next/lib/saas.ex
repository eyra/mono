defmodule Next.SaaS do
  @moduledoc "Next, Eyra's SaaS on Mica."
  use Mica.SaaS
  use Mica.FeatureFlags

  alias Systems.Pool

  @impl true
  def systems do
    Mica.Systems.all() ++
      [
        Next.Systems.WellKnown.System,
        Next.Systems.Account.System,
        Next.Systems.E2E.System,
        Next.Systems.Panl.System,
        Next.Systems.Announcement.System,
        Next.Systems.Graphite.System,
        Next.Systems.Onyx.System,
        Next.Systems.Student.System,
        Next.Systems.Zircon.System,
        Next.Systems.Paper.System,
        Next.Systems.Probe.System,
        Next.Systems.Storybook.System
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
      e2e: false,
      storybook: false
    ]
  end

  @impl true
  def start_pages, do: Next.StartPages

  @impl true
  def menu_items, do: NextWeb.Menu.Items

  @impl true
  def menu_builder(:workspace), do: NextWeb.Layouts.Workspace.MenuBuilder
  def menu_builder(:website), do: NextWeb.Layouts.Website.MenuBuilder
  def menu_builder(:stripped), do: NextWeb.Layouts.Stripped.MenuBuilder

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
      do: MicaWeb.ReturnTo.append("/user/auth/identify/participant", return_to),
      else: "/user/signin"
  end

  # With sign-in codes on, the code page signs new users up too.
  @impl true
  def sign_up_page(user_type, post_signup_action) do
    if feature_enabled?(:otp), do: code_sign_up_page(user_type, post_signup_action)
  end

  defp code_sign_up_page(:creator, _post_signup_action), do: "/user/auth/identify"

  defp code_sign_up_page(:participant, post_signup_action) do
    MicaWeb.ReturnTo.append(
      "/user/auth/identify/participant",
      post_signup_return_to(post_signup_action)
    )
  end

  # The code flow joins a pool through its join page, where the password sign-up
  # page took `post_signup_action=add_to_panl` or `join_pool:<slug>`.
  defp post_signup_return_to("add_to_panl") do
    if feature_enabled?(:panl), do: "/pool/panl/join"
  end

  defp post_signup_return_to("join_pool:" <> slug) do
    if existing_pool_slug?(slug), do: "/pool/#{slug}/join"
  end

  defp post_signup_return_to(_post_signup_action), do: nil

  # The join page takes only a slug that is an existing atom naming a pool.
  defp existing_pool_slug?(slug) do
    match?(%Pool.Model{}, Pool.Public.get_by_slug(String.to_existing_atom(slug)))
  rescue
    ArgumentError -> false
  end
end
