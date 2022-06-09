defmodule Systems.DataDonation.ThanksPage do
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

  defp survey_link(participant) do
    link_as_string(
      dgettext("eyra-data-donation", "survey.link"),
      "https://survey.uu.nl/jfe/form/SV_aeFIXlMaKK7wZkq?participant_id=#{participant}"
    )
  end

  defp link_as_string(label, url) do
    label
    |> Phoenix.HTML.Link.link(
      class: "text-primary underline",
      target: "_blank",
      to: url
    )
    |> Phoenix.HTML.safe_to_string()
  end

  defp descriptions(participant) do
    dgettext("eyra-data-donation", "thanks.description", survey_link: survey_link(participant))
    |> String.split("<br>")
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
              <div class="flex flex-col gap-4">
                <div :for={description <- descriptions(@participant)} class="text-bodylarge font-body">
                  {raw(description)}
                </div>
              </div>
            </div>
            <div class="flex-shrink-0">
              <div class="rounded-lg bg-grey5">
                <img src={@vm.researcher.institution.image} alt={@vm.researcher.institution.name} />
                <div class="flex flex-col gap-3 p-4">
                  <div class="text-title7 font-title7 text-grey1">
                    {@vm.researcher.name}
                  </div>
                  <div class="text-caption font-caption text-grey1">
                    {@vm.researcher.job_title}
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
