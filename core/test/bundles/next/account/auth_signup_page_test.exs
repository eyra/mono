defmodule Next.Account.AuthSignupPageTest do
  use CoreWeb.ConnCase, async: false
  import Phoenix.LiveViewTest

  setup do
    original_providers =
      Application.get_env(:core, :account, []) |> Keyword.get(:auth_providers, [])

    on_exit(fn ->
      account = Application.get_env(:core, :account, [])

      Application.put_env(
        :core,
        :account,
        Keyword.put(account, :auth_providers, original_providers)
      )
    end)

    :ok
  end

  defp set_providers(providers) do
    account = Application.get_env(:core, :account, [])
    Application.put_env(:core, :account, Keyword.put(account, :auth_providers, providers))
  end

  describe "rendering" do
    test "renders welcome and Sign in with [provider] button for known provider", %{conn: conn} do
      set_providers([:surfconext])
      {:ok, _view, html} = live(conn, "/user/auth/surfconext")

      assert html =~ "Welcome"
      assert html =~ "Surfconext"
      assert html =~ "/auth/surfconext"
      assert html =~ "/images/logos/platforms/surfconext.svg"
    end

    test "derives name, logo, and auth_path from the provider key", %{conn: conn} do
      set_providers([:mock])
      {:ok, _view, html} = live(conn, "/user/auth/mock")

      assert html =~ "Mock"
      assert html =~ "/auth/mock"
      assert html =~ "/images/logos/platforms/mock.svg"
    end
  end

  describe "unknown provider" do
    test "redirects to signin when provider not in auth_providers", %{conn: conn} do
      set_providers([:surfconext])

      assert {:error, {:redirect, %{to: "/user/signin"}}} =
               live(conn, "/user/auth/unknown")
    end

    test "redirects to signin when auth_providers is empty", %{conn: conn} do
      set_providers([])

      assert {:error, {:redirect, %{to: "/user/signin"}}} =
               live(conn, "/user/auth/surfconext")
    end
  end
end
