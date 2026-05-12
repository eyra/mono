defmodule Systems.Account.UserFormTest do
  use CoreWeb.ConnCase, async: false
  import Phoenix.LiveViewTest

  @policy_urls Application.compile_env(:core, :policy_urls)

  describe "password_signup form" do
    test "renders Next policy links with configured URLs", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/user/signup/participant")

      assert html =~ @policy_urls[:next_terms]
      assert html =~ @policy_urls[:next_privacy]
      refute html =~ @policy_urls[:panl_terms]
      refute html =~ @policy_urls[:panl_privacy]
    end

    test "renders all policy links when Panl visible", %{conn: conn} do
      {:ok, view, _html} =
        live(conn, "/user/signup/participant?post_signup_action=add_to_panl")

      html = render(view)

      assert html =~ @policy_urls[:next_terms]
      assert html =~ @policy_urls[:next_privacy]
      assert html =~ @policy_urls[:panl_terms]
      assert html =~ @policy_urls[:panl_privacy]
    end
  end
end
