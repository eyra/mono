defmodule Systems.DataDonation.ThanksWhatsappChatPage do
  import Phoenix.LiveView

  use Surface.LiveView, layout: {CoreWeb.LayoutView, "live.html"}
  use CoreWeb.LiveLocale
  use CoreWeb.LiveAssignHelper
  use CoreWeb.Layouts.Stripped.Component, :data_donation

  import CoreWeb.Gettext

  alias CoreWeb.UI.MarginY
  alias CoreWeb.UI.Container.{ContentArea, SheetArea}
  alias CoreWeb.Layouts.Stripped.Component, as: Stripped

  alias Frameworks.Pixel.Text.{Title1}

  alias Systems.{
    DataDonation
  }

  data(tool, :any)
  data(participant, :any)

  def mount(%{"id" => id, "participant" => participant} = _params, _session, socket) do
    {
      :ok,
      socket
      |> assign(
        participant: participant,
        vm: DataDonation.Context.get(id)
      )
      |> update_menus()
    }
  end

  defp descriptions(_participant) do
    dgettext("eyra-data-donation", "thanks.whatsapp.description")
    |> String.split("<br>")
  end

  def render(assigns) do
    ~F"""
    <Stripped user={@current_user} menus={@menus}>
      <ContentArea>
        <MarginY id={:page_top} />
        <SheetArea>
          <div class="flex flex-col sm:flex-row gap-10">
            <div>
              <Title1>{dgettext("eyra-data-donation", "thanks.title")}</Title1>
              <div class="flex flex-col gap-4">
                <div :for={description <- descriptions(@participant)} class="text-bodylarge font-body">
                  {raw(description)}
                </div>
              </div>
            </div>
          </div>
        </SheetArea>
      </ContentArea>
    </Stripped>
    """
  end
end
