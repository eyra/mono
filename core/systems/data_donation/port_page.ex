defmodule Systems.DataDonation.PortPage do
  defmodule StoreResultsError do
    @moduledoc false
    defexception [:message]
  end

  import Phoenix.LiveView

  use Surface.LiveView, layout: {CoreWeb.LayoutView, "live.html"}
  use CoreWeb.LiveUri
  use CoreWeb.LiveLocale
  use CoreWeb.LiveAssignHelper

  alias CoreWeb.Layouts.App.Component, as: App
  alias CoreWeb.Menu

  alias Systems.{
    DataDonation
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
        %{assigns: %{session: session, vm: %{storage: storage_key} = vm}} = socket,
        platform,
        data
      )
      when is_binary(data) do
    storage = storage(storage_key)
    storage.store(Map.put(session, "platform", platform), vm, data)

    socket
  end

  defp config() do
    Application.fetch_env!(:core, :data_donation_storage_backend)
  end

  defp storage(storage_key) do
    config = config()

    case Keyword.get(config, storage_key) do
      nil ->
        raise StoreResultsError, "Could not store the results, invalid config for #{storage_key}"

      value ->
        value
    end
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
