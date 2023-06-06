defmodule Systems.DataDonation.ThanksWhatsappPage do
  import Phoenix.Component

  use CoreWeb, :live_view
  use CoreWeb.LiveLocale
  use CoreWeb.LiveAssignHelper
  use CoreWeb.Layouts.Stripped.Component, :data_donation

  import CoreWeb.Gettext

  alias CoreWeb.UI.Area
  alias CoreWeb.UI.Margin

  alias Frameworks.Pixel.Text

  alias Systems.{
    DataDonation
  }

  # data(tool, :any)
  # data(participant, :any)

  def mount(%{"id" => id, "participant" => participant} = _params, _session, socket) do
    {
      :ok,
      socket
      |> assign(
        participant: participant,
        vm: DataDonation.Public.get(id)
      )
      |> update_menus()
    }
  end

  defp descriptions(_participant) do
    dgettext("eyra-data-donation", "thanks.whatsapp.description")
    |> String.split("<br>")
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.stripped user={@current_user} menus={@menus}>
      <Area.content>
        <Margin.y id={:page_top} />
        <Area.sheet>
          <div class="flex flex-col sm:flex-row gap-10">
            <div>
              <Text.title1><%= dgettext("eyra-data-donation", "thanks.title") %></Text.title1>
              <div class="flex flex-col gap-4">
                <%= for description <- descriptions(@participant) do %>
                  <div class="text-bodylarge font-body">
                    <%= raw(description) %>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        </Area.sheet>
      </Area.content>
    </.stripped>
    """
  end
end
