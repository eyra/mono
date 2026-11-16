defmodule Systems.Assignment.GeneralFormTest do
  use MicaWeb.ConnCase, async: false
  import Phoenix.LiveViewTest

  alias Mica.Repo
  alias Systems.Assignment

  defmodule GeneralFormView do
    use Phoenix.LiveView

    def mount(_params, %{"info" => info}, socket) do
      {:ok, assign(socket, info: info)}
    end

    def render(assigns) do
      ~H"""
      <.live_component
        module={Assignment.GeneralForm}
        id="general"
        entity={@info}
        viewport={%{}}
        breakpoint={{:unknown, nil}}
        content_flags={%{expected: true, language: true}}
      />
      """
    end

    def handle_info(_message, socket), do: {:noreply, socket}
  end

  describe "save" do
    setup %{conn: conn} do
      info =
        Factories.insert!(:assignment_info, %{
          subject_count: 10,
          title: "Old title",
          logo_url: "http://localhost/uploads/abc_logo.png"
        })

      Factories.insert!(:assignment, %{info: info})

      {:ok, view, _html} =
        conn
        |> Map.put(:request_path, "/assignment/general_form")
        |> live_isolated(GeneralFormView, session: %{"info" => info})

      %{view: view, info: info}
    end

    test "saves the subject count and language", %{view: view, info: info} do
      view
      |> element("#general_general")
      |> render_change(%{"info_model" => %{"subject_count" => "25", "language" => "nl"}})

      assert %{subject_count: 25, language: :nl} = Repo.get!(Assignment.InfoModel, info.id)
    end

    test "ignores other info fields sent with the form", %{view: view, info: info} do
      view
      |> element("#general_general")
      |> render_change(%{
        "info_model" => %{
          "subject_count" => "25",
          "title" => "New title",
          "logo_url" => "https://example.com/logo.png"
        }
      })

      assert %{
               subject_count: 25,
               title: "Old title",
               logo_url: "http://localhost/uploads/abc_logo.png"
             } = Repo.get!(Assignment.InfoModel, info.id)
    end
  end
end
