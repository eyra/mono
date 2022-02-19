defmodule Systems.DataDonation.SubmitDataSheet do
  use CoreWeb.UI.LiveComponent
  alias Surface

  alias Frameworks.Pixel.Text.{Title1, Body, Label}
  alias Frameworks.Pixel.Line

  prop(props, :map, required: true)

  def update(%{id: id}, socket) do
    {:ok, assign(socket, id: id)}
  end

  defp submit_button() do
    label = dgettext("eyra-data-donation", "submit.data.button")

    %{
      action: %{type: :submit},
      face: %{type: :primary, label: label}
    }
  end

  defp terms_link() do
    link_as_string(
      dgettext("eyra-ui", "terms.link"),
      "/gebruikersvoorwaarden-port.pdf"
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

  def render(assigns) do
    ~F"""
      <ContentArea>
        <MarginY id={:page_top} />
        <SheetArea>
          <div class="flex flex-col">
            <Title1>{dgettext("eyra-data-donation", "submit_data.title")}</Title1>
            <div class="no-extraction-data-yet">
              <Body>
                {dgettext("eyra-data-donation", "no.extraction.data.yet.description")}
              </Body>
            </div>
            <form class="donate-form hidden" :on-submit={"donate", target: :live_view}>
              <input type="hidden" name="data" value="...">
              <Body>
                {dgettext("eyra-data-donation", "submit_data.description")}
              </Body>
              <Spacing value="M" />
              <Label>
                {raw(dgettext("eyra-data-donation", "terms.description", link: terms_link()))}
              </Label>
              <Spacing value="S" />
              <Wrap>
                <DynamicButton vm={submit_button()} />
              </Wrap>
              <Spacing value="L" />

              <Line />
              <Spacing value="M" />
              <p class="extracted overflow-scroll">...</p>
              <Spacing value="M" />
              <Line />
              <Spacing value="M" />

              <Wrap>
                <DynamicButton vm={submit_button()} />
              </Wrap>
            </form>
          </div>
        </SheetArea>
      </ContentArea>
    """
  end
end
