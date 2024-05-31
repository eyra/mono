defmodule Systems.Account.AwaitConfirmation do
  use CoreWeb, :live_view
  import CoreWeb.Layouts.Stripped.Html
  import CoreWeb.Layouts.Stripped.Composer

  alias Frameworks.Pixel.Text

  def mount(_params, _session, socket) do
    require_feature(:password_sign_in)

    {
      :ok,
      socket
      |> assign(active_menu_item: :profile)
      |> update_menus()
    }
  end

  # data(changeset, :any)
  @impl true
  def render(assigns) do
    ~H"""
    <.stripped menus={@menus}>
      <div>
        <Area.sheet>
        <Margin.y id={:page_top} />
          <div class="flex flex-col items-center">
            <Text.title2><%= dgettext("eyra-account", "await.confirmation.title") %></Text.title2>
            <Text.body align="text-center"><%= dgettext("eyra-account", "await.confirmation.description") %></Text.body>
          </div>
        </Area.sheet>
      </div>
    </.stripped>
    """
  end
end
