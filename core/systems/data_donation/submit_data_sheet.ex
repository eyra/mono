defmodule Systems.DataDonation.SubmitDataSheet do
  use CoreWeb, :live_component

  alias Frameworks.Pixel.Text
  import Frameworks.Pixel.Line

  import Systems.DataDonation.FakeForm
  import Systems.DataDonation.S3Form
  import Systems.DataDonation.CenterdataForm

  @impl true
  def update(%{id: id, recipient: recipient} = params, socket) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        recipient: recipient
      )
      |> update_form(params)
      |> update_buttons()
    }
  end

  defp update_form(socket, params) do
    socket |> assign(form: get_form(params))
  end

  defp get_form(%{storage: :fake}) do
    %{
      function: &fake_form/1,
      props: %{}
    }
  end

  defp get_form(%{storage: :s3}) do
    %{
      function: &s3_form/1,
      props: %{}
    }
  end

  defp get_form(%{storage: :centerdata, storage_info: storage_info, session: session}) do
    %{
      function: &centerdata_form/1,
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

  # data(recipient, :any)
  # data(form, :any)
  # data(buttons, :any)

  attr(:props, :map, required: true)
  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
      <Margin.y id={:page_top} />
      <Area.sheet>
        <div class="flex flex-col">
          <Text.title1><%= dgettext("eyra-data-donation", "submit_data.title") %></Text.title1>
          <div class="no-extraction-data-yet">
            <Text.body>
              <%= dgettext("eyra-data-donation", "no.extraction.data.yet.description") %>
            </Text.body>
          </div>
          <.function_component {@form}>
            <div>
              <Text.body>
                <%= dgettext("eyra-data-donation", "submit_data.description") %>
              </Text.body>
              <.spacing value="L" />

              <.line />
              <p class="extracted overflow-scroll">...</p>
              <.spacing value="M" />
              <.line />
              <.spacing value="L" />
            </div>
            <Text.body>
              <%= dgettext("eyra-data-donation", "submit_data.action.label", recipient: @recipient) %>
            </Text.body>
            <.spacing value="M" />
            <div class="flex flex-row gap-4">
              <%= for button <- @buttons do %>
                <Button.dynamic {button} />
              <% end %>
            </div>
          </.function_component>
        </div>
      </Area.sheet>
      </Area.content>
    </div>
    """
  end
end
