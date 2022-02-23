defmodule Systems.DataDonation.ThanksPage do
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Stripped.Component, :data_donation

  import CoreWeb.Gettext

  alias CoreWeb.Layouts.Stripped.Component, as: Stripped
  alias Frameworks.Pixel.Text.{Title1}

  alias Systems.{
    DataDonation
  }

  data(tool, :any)

  def mount(_, _session, socket) do
    {
      :ok,
      socket
      |> assign(vm: DataDonation.PilotModel.view_model())
      |> update_menus()
    }
  end

  def render(assigns) do
    ~F"""
    <Stripped user={@current_user} menus={@menus}>
      <ContentArea>
        <MarginY id={:page_top} />
        <SheetArea>
          <div class="flex flex-col sm:flex-row gap-10 ">
            <div>
              <Title1>{dgettext("eyra-data-donation", "thanks.title")}</Title1>
              <div class="text-bodylarge font-body">
                {dgettext("eyra-data-donation", "thanks.description")}
              </div>
            </div>
            <div class="flex-shrink-0">
              <div class="rounded-lg bg-grey5">
                <img src={@vm.image} alt={@vm.institution} />
                <div class="flex flex-col gap-3 p-4">
                  <div class="text-title7 font-title7 text-grey1">
                    {@vm.researcher}
                  </div>
                  <div class="text-caption font-caption text-grey1">
                    {@vm.job_title}
                  </div>
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
