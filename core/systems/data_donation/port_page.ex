defmodule Systems.DataDonation.PortPage do
  import Phoenix.LiveView

  require Logger

  use Surface.LiveView, layout: {CoreWeb.LayoutView, "live.html"}
  use CoreWeb.LiveUri
  use CoreWeb.LiveLocale
  use CoreWeb.LiveRemoteIp
  use CoreWeb.LiveAssignHelper

  alias CoreWeb.Layouts.App.Component, as: App
  alias CoreWeb.Menu

  alias Systems.{
    DataDonation,
    Rate
  }

  data(result, :any)
  data(tool, :any)
  data(locale, :any)
  data(participant, :any)

  @impl true
  def mount(
        %{"id" => id, "session" => %{"participant" => participant} = session} = _params,
        %{"locale" => locale} = _session,
        socket
      ) do
    vm = DataDonation.Context.get_port(id)

    {:ok,
     assign(socket, id: id, vm: vm, session: session, locale: locale, participant: participant)
     |> update_menus()}
  end

  @impl true
  def handle_uri(socket) do
    update_menus(socket)
  end

  def update_menus(socket) do
    socket
    |> assign(
      menus: %{
        desktop_navbar: %{
          right: [Menu.Helpers.language_switch_item(socket, :desktop_navbar, true)]
        }
      }
    )
  end

  def store_results(
        %{assigns: %{session: session, remote_ip: remote_ip, vm: %{storage: storage_key} = vm}} =
          socket,
        key,
        json_string
      )
      when is_binary(json_string) do
    state = Map.merge(session, %{"key" => key})
    packet_size = String.length(json_string)

    with :granted <- Rate.Public.request_permission(:azure_blob, remote_ip, packet_size) do
      %{
        storage_key: storage_key,
        state: state,
        vm: vm,
        data: json_string
      }
      |> DataDonation.Delivery.new()
      |> Oban.insert()
    end

    socket
  end

  @impl true
  def handle_event(
        "donate",
        %{"__type__" => "CommandSystemDonate", "key" => key, "json_string" => json_string},
        socket
      ) do
    {
      :noreply,
      socket |> store_results(key, json_string)
    }
  end

  @impl true
  def render(assigns) do
    ~F"""
    <App user={@current_user} logo={:port_wide} menus={@menus}>
      <div
        class="h-full"
        id="port"
        phx-hook="Port"
        data-locale={@locale}
        data-participant={@participant}
      />
    </App>
    """
  end
end
