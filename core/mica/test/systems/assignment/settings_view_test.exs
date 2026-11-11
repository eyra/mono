defmodule Systems.Assignment.SettingsViewTest do
  use MicaWeb.ConnCase, async: false
  import Phoenix.LiveViewTest

  alias Systems.Assignment

  defmodule HostView do
    use MicaWeb, :live_view_fabric

    @impl true
    def mount(_params, %{"assignment" => assignment}, socket) do
      fabric = %Fabric.Model{parent: nil, self: %Fabric.LiveView.RefModel{pid: self()}}

      {
        :ok,
        socket
        |> assign(fabric: fabric, assignment: assignment)
        |> compose_child(:settings)
      }
    end

    @impl true
    def compose(:settings, %{assignment: assignment}) do
      %{
        module: Assignment.SettingsView,
        params: %{
          entity: assignment,
          project_node: nil,
          storage_endpoint: nil,
          uri_origin: "",
          viewport: nil,
          breakpoint: {:unknown, nil},
          title: "Settings",
          content_flags: %{
            branding: false,
            information: false,
            privacy: false,
            consent: true,
            helpdesk: false,
            affiliate: false
          }
        }
      }
    end

    @impl true
    def render(assigns) do
      ~H"""
      <.child name={:settings} fabric={@fabric} />
      """
    end

    @impl true
    def handle_info(_message, socket), do: {:noreply, socket}
  end

  test "the consent settings say that participants already taking part won't be asked", %{
    conn: conn
  } do
    assignment = Assignment.Factories.create_assignment_with_consent()

    {:ok, view, _html} =
      conn
      |> Map.put(:request_path, "/assignment/settings")
      |> live_isolated(HostView, session: %{"assignment" => assignment})

    assert view
           |> element("[data-testid='consent-existing-participants']")
           |> render() =~
             "Only participants who join after that are asked for consent."
  end
end
