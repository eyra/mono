defmodule Systems.DataDonation.WelcomeSheet do
  use CoreWeb.UI.LiveComponent

  alias Frameworks.Pixel.Text.Title1

  prop(props, :map, required: true)

  data(researcher, :string)
  data(pronoun, :string)
  data(research_topic, :string)
  data(job_title, :string)
  data(image, :string)
  data(institution, :string)
  data(file_type, :string)

  def update(
        %{
          id: id,
          props: %{
            researcher: researcher,
            pronoun: pronoun,
            research_topic: research_topic,
            job_title: job_title,
            image: image,
            institution: institution,
            file_type: file_type
          }
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
        research_topic: research_topic,
        job_title: job_title,
        image: image,
        institution: institution,
        file_type: file_type
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
              <div class="flex flex-col gap-4">
                <div class="text-bodylarge font-body">
                  {dgettext("eyra-data-donation", "welcome.description.1", researcher: @researcher, file_type: @file_type)}
                </div>
                <div class="text-bodylarge font-body">
                  {dgettext("eyra-data-donation", "welcome.description.2", researcher: @researcher, file_type: @file_type)}
                </div>
                <div class="text-bodylarge font-body">
                  {dgettext("eyra-data-donation", "welcome.description.3", researcher: @researcher, file_type: @file_type)}
                </div>
              </div>
            </div>
            <div class="flex-shrink-0">
              <div class="rounded-lg bg-grey5">
                <img src={@image} alt={@institution} />
                <div class="flex flex-col gap-3 p-4">
                  <div class="text-title7 font-title7 text-grey1">
                    {@researcher}
                  </div>
                  <div class="text-caption font-caption text-grey1">
                    {@job_title}
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
