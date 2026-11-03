defmodule Systems.Affiliate.FormTest do
  use MicaWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  alias Mica.Repo
  alias Systems.Affiliate

  defmodule FormView do
    use Phoenix.LiveView

    def mount(_params, %{"affiliate" => affiliate}, socket) do
      {:ok, assign(socket, affiliate: affiliate)}
    end

    def render(assigns) do
      ~H"""
      <.live_component module={Affiliate.Form} id="affiliate" affiliate={@affiliate} />
      """
    end

    def handle_info(_message, socket), do: {:noreply, socket}
  end

  setup %{conn: conn} do
    affiliate = Factories.insert!(:affiliate, %{callback_url: nil, redirect_url: nil})

    {:ok, view, _html} =
      conn
      |> Map.put(:request_path, "/affiliate/form")
      |> live_isolated(FormView, session: %{"affiliate" => affiliate})

    %{view: view, affiliate: affiliate}
  end

  test "doesn't save an http callback URL and asks for https", %{
    view: view,
    affiliate: affiliate
  } do
    html =
      view
      |> element("form")
      |> render_change(%{"model" => %{"callback_url" => "http://example.org/callback"}})

    assert html =~ "Please use an address that starts with https://"
    assert %{callback_url: nil} = Repo.get!(Affiliate.Model, affiliate.id)
  end

  test "doesn't save a private callback URL and asks for a public one", %{
    view: view,
    affiliate: affiliate
  } do
    html =
      view
      |> element("form")
      |> render_change(%{"model" => %{"callback_url" => "https://10.1.2.3/callback"}})

    assert html =~ "Please use an address that exists on the public internet"
    assert %{callback_url: nil} = Repo.get!(Affiliate.Model, affiliate.id)
  end

  test "doesn't save a redirect URL to localhost and asks for a public one", %{
    view: view,
    affiliate: affiliate
  } do
    html =
      view
      |> element("form")
      |> render_change(%{"model" => %{"redirect_url" => "https://localhost/return"}})

    assert html =~ "Please use an address that exists on the public internet"
    assert %{redirect_url: nil} = Repo.get!(Affiliate.Model, affiliate.id)
  end

  test "doesn't save a host that doesn't resolve and answers as for a private one", %{
    view: view,
    affiliate: affiliate
  } do
    html =
      view
      |> element("form")
      |> render_change(%{"model" => %{"callback_url" => "https://next-t0275.invalid/callback"}})

    assert html =~ "Please use an address that exists on the public internet"
    assert %{callback_url: nil} = Repo.get!(Affiliate.Model, affiliate.id)
  end

  test "doesn't save a port other than 443", %{view: view, affiliate: affiliate} do
    html =
      view
      |> element("form")
      |> render_change(%{"model" => %{"callback_url" => "https://1.1.1.1:22/callback"}})

    assert html =~ "Please use an address without a port number"
    assert %{callback_url: nil} = Repo.get!(Affiliate.Model, affiliate.id)
  end
end
