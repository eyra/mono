defmodule Systems.Assignment.BrandingFormTest do
  use CoreWeb.ConnCase, async: false
  import Phoenix.LiveViewTest

  alias Core.Repo
  alias Systems.Assignment

  defmodule BrandingFormView do
    use Phoenix.LiveView

    def mount(_params, %{"info" => info}, socket) do
      {:ok, assign(socket, info: info)}
    end

    def render(assigns) do
      ~H"""
      <.live_component
        module={Assignment.BrandingForm}
        id="branding"
        entity={@info}
        viewport={%{}}
        breakpoint={{:unknown, nil}}
      />
      """
    end

    def handle_info(_message, socket), do: {:noreply, socket}
  end

  describe "save" do
    setup %{conn: conn} do
      info =
        Factories.insert!(:assignment_info, %{
          title: "Old title",
          logo_url: "http://localhost/uploads/abc_logo.png"
        })

      Factories.insert!(:assignment, %{info: info})

      {:ok, view, _html} =
        conn
        |> Map.put(:request_path, "/assignment/branding_form")
        |> live_isolated(BrandingFormView, session: %{"info" => info})

      %{view: view, info: info}
    end

    test "saves the title and subtitle", %{view: view, info: info} do
      view
      |> element("#branding_general")
      |> render_change(%{"info_model" => %{"title" => "New title", "subtitle" => "Sub"}})

      assert %{title: "New title", subtitle: "Sub"} =
               Repo.get!(Assignment.InfoModel, info.id)
    end

    test "ignores a logo URL or header image sent with the form", %{view: view, info: info} do
      view
      |> element("#branding_general")
      |> render_change(%{
        "info_model" => %{
          "title" => "New title",
          "logo_url" => "http://169.254.169.254/latest/meta-data/",
          "image_id" => "other"
        }
      })

      assert %{
               title: "New title",
               logo_url: "http://localhost/uploads/abc_logo.png",
               image_id: image_id
             } = Repo.get!(Assignment.InfoModel, info.id)

      assert image_id == info.image_id
    end
  end
end
