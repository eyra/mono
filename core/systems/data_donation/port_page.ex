defmodule Systems.DataDonation.PortPage do
  import Phoenix.LiveView

  use Surface.LiveView, layout: {CoreWeb.LayoutView, "live.html"}
  use CoreWeb.LiveUri
  use CoreWeb.LiveLocale
  use CoreWeb.LiveAssignHelper
  use CoreWeb.Layouts.Stripped.Component, :data_donation

  alias CoreWeb.Layouts.Stripped.Component, as: Stripped

  data(result, :any)
  data(tool, :any)
  data(locale, :any)

  @impl true
  def mount(
        %{"session" => session} = _params,
        %{"locale" => locale} = _session,
        socket
      ) do
    {:ok,
     assign(socket, session: session, locale: locale)
     |> update_menus()}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Stripped user={@current_user} menus={@menus}>
      <div
        id="port"
        phx-hook="Port"
        data-locale={@locale}
      />
    </Stripped>
    """
  end
end
