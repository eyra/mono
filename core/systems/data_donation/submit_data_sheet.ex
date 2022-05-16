defmodule Systems.DataDonation.SubmitDataSheet do
  use CoreWeb.UI.LiveComponent
  alias Surface

  alias Frameworks.Pixel.Text.{Title1, Body}
  alias Frameworks.Pixel.Line

  alias Surface.Components.Dynamic

  prop(props, :map, required: true)

  data(researcher, :string)
  data(form, :any)

  def update(%{id: id, props: %{researcher: researcher} = props}, socket) do
    form = get_form(props)
    {:ok, socket |> assign(id: id, researcher: researcher, form: form)}
  end

  defp get_form(%{storage: :s3}) do
    %{
      module: Systems.DataDonation.S3Form,
      props: %{}
    }
  end

  defp get_form(%{storage: :centerdata, storage_info: storage_info, session: session}) do
    %{
      module: Systems.DataDonation.CenterdataForm,
      props: %{session: session, storage_info: storage_info}
    }
  end

  defp submit_button() do
    label = dgettext("eyra-data-donation", "submit.data.button")

    %{
      action: %{type: :submit},
      face: %{type: :primary, label: label}
    }
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
            <Dynamic.Component module={@form.module} {...@form.props} >
              <div>
                <Body>
                  {dgettext("eyra-data-donation", "submit_data.description", researcher: @researcher)}
                </Body>
                <Spacing value="L" />

                <Line />
                <p class="extracted overflow-scroll">...</p>
                <Spacing value="M" />
                <Line />
                <Spacing value="M" />

                <Wrap>
                  <DynamicButton vm={submit_button()} />
                </Wrap>
              </div>
            </Dynamic.Component>
          </div>
        </SheetArea>
      </ContentArea>
    """
  end
end
