defmodule Next.Account.AuthCodeVerifyPageTest do
  @moduledoc """
  Wires up the rate-limit path end-to-end at the LiveView level: hitting
  the attempts limit on the verify page must bounce back to
  /user/auth/identify with the RATE-LIMIT flash, not the "code expired"
  one. See Flux 10025618754.
  """
  use CoreWeb.ConnCase, async: false
  use Core.FeatureFlags.Test
  use Gettext, backend: CoreWeb.Gettext

  import Phoenix.LiveViewTest

  alias Core.Repo
  alias Systems.Account.AuthCodeModel

  describe "/user/auth/verify rate limit" do
    test "redirects to /user/auth/identify with the rate-limit message after exhausting attempts",
         %{conn: conn} do
      set_feature_flag(:otp, true)

      email = "rate-limited@example.com"
      {_code, auth_code} = AuthCodeModel.build(email, nil)
      Repo.insert!(%{auth_code | attempts: 5})

      {:ok, view, _html} = live(conn, ~p"/user/auth/verify?email=#{email}")

      result = render_submit(view, "verify", %{"code" => "999999"})
      assert {:error, {:live_redirect, %{to: "/user/auth/identify"}}} = result

      {:ok, _view, html} = follow_redirect(result, conn)

      assert html =~ dgettext("eyra-account", "auth.code.max_attempts")
      refute html =~ dgettext("eyra-account", "auth.code.expired")
    end

    test "with attempts: 4, a wrong code stays on the page with the invalid message",
         %{conn: conn} do
      # Pins the boundary the other way: the user still has one attempt on
      # attempt #5, so a wrong code shows the inline error — no redirect,
      # no rate-limit flash.
      set_feature_flag(:otp, true)

      email = "boundary@example.com"
      {_code, auth_code} = AuthCodeModel.build(email, nil)
      Repo.insert!(%{auth_code | attempts: 4})

      {:ok, view, _html} = live(conn, ~p"/user/auth/verify?email=#{email}")

      html = render_submit(view, "verify", %{"code" => "999999"})

      assert html =~ dgettext("eyra-account", "auth.code.invalid")
      refute html =~ dgettext("eyra-account", "auth.code.max_attempts")
      refute html =~ dgettext("eyra-account", "auth.code.expired")
    end
  end
end
