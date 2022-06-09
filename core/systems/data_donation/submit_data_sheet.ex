defmodule Systems.DataDonation.SubmitDataSheet do
  use CoreWeb.UI.LiveComponent
  alias Surface

  alias Frameworks.Pixel.Text.{Title1, Body}
  alias Frameworks.Pixel.Line

  alias Surface.Components.Dynamic

  prop(props, :map, required: true)

  data(recipient, :any)
  data(form, :any)
  data(buttons, :any)

  def update(%{id: id, props: %{recipient: recipient} = props}, socket) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        recipient: recipient
      )
      |> update_form(props)
      |> update_buttons()
    }
  end

  defp update_form(socket, props) do
    socket |> assign(form: get_form(props))
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

  defp update_buttons(socket) do
    socket |> assign(buttons: [donate_button(), decline_button()])
  end

  defp donate_button() do
    label = dgettext("eyra-data-donation", "submit.data.button")

    %{
      action: %{type: :submit, form_id: "donate-form"},
      face: %{type: :primary, label: label}
    }
  end

  defp decline_button() do
    label = dgettext("eyra-data-donation", "decline.data.button")

    %{
      action: %{type: :submit, form_id: "decline-form"},
      face: %{type: :secondary, text_color: "text-delete", label: label}
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
                  {dgettext("eyra-data-donation", "submit_data.description")}
                </Body>
                <Spacing value="L" />

                <Line />
                <p class="extracted overflow-scroll">...</p>
                <Spacing value="M" />
                <Line />
                <Spacing value="L" />
              </div>
              <Body>
                {dgettext("eyra-data-donation", "submit_data.action.label", recipient: @recipient)}
              </Body>
              <Spacing value="M" />
              <div class="flex flex-row gap-4">
                <DynamicButton :for={button <- @buttons} vm={button} />
              </div>
            </Dynamic.Component>
          </div>
        </SheetArea>
      </ContentArea>
    """
  end
end
