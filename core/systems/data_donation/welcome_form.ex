defmodule Systems.DataDonation.WelcomeSheet do
  use CoreWeb.UI.LiveComponent

  alias Frameworks.Pixel.Text.Title1

  prop(props, :map, required: true)

  data(researcher, :string)
  data(pronoun, :string)
  data(research_topic, :string)

  def update(
        %{
          id: id,
          props: %{researcher: researcher, pronoun: pronoun, research_topic: research_topic}
        },
        socket
      ) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        researcher: researcher,
        pronoun: pronoun,
        research_topic: research_topic
      )
    }
  end

  def render(assigns) do
    ~F"""
      <ContentArea>
        <MarginY id={:page_top} />
        <SheetArea>
          <div class="flex flex-col sm:flex-row gap-10 ">
            <div>
              <Title1>{dgettext("eyra-data-donation", "welcome.title")}</Title1>
              <div class="text-bodylarge font-body">
                {dgettext("eyra-data-donation", "welcome.description", researcher: @researcher, pronoun: @pronoun, research_topic: @research_topic)}
              </div>
            </div>
            <div class="flex-shrink-0">
              <div class="rounded-lg bg-grey5">
                <img src={"/images/uu_card.svg"} alt="University Utrecht" />
                <div class="flex flex-col gap-3 p-4">
                  <div class="text-title7 font-title7 text-grey1">
                    {@researcher}
                  </div>
                  <div class="text-caption font-caption text-grey1">
                    Assistant Professor
                  </div>
                </div>
              </div>
            </div>
          </div>
        </SheetArea>
      </ContentArea>
    """
  end
end
