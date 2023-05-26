defmodule Systems.DataDonation.WelcomeSheet do
  use CoreWeb, :live_component

  alias Frameworks.Pixel.Text

  @impl true
  def update(
        %{
          id: id,
          props: %{
            recipient: recipient,
            researcher: researcher,
            research_description: research_description,
            platform: platform
          }
        },
        socket
      ) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        recipient: recipient,
        researcher: researcher,
        research_description: research_description,
        platform: platform
      )
    }
  end

  defp descriptions(assigns) do
    [
      descriptions_top(assigns),
      descriptions_middle(assigns),
      descriptions_bottom(assigns)
    ]
    |> Enum.join("<br>")
    # the split below also splits the original descriptions (if they contain <br> tags)
    |> String.split("<br>")
  end

  defp descriptions_top(%{recipient: recipient}) do
    dgettext("eyra-data-donation", "welcome.description.top", recipient: recipient)
  end

  defp descriptions_middle(%{research_description: research_description}) do
    current_locale = Gettext.get_locale(CoreWeb.Gettext)
    Map.get(research_description, current_locale)
  end

  defp descriptions_bottom(%{recipient: recipient, platform: platform}) do
    dgettext("eyra-data-donation", "welcome.description.bottom",
      recipient: recipient,
      platform: platform
    )
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
      <Margin.y id={:page_top} />
      <Area.sheet>
        <div class="flex flex-col sm:flex-row gap-10">
          <div>
            <Text.title1><%= dgettext("eyra-data-donation", "welcome.title") %></Text.title1>
            <div class="flex flex-col gap-4">
              <%= for description <- descriptions(assigns) do %>
                <div class="text-bodylarge font-body">
                  <%= raw(description) %>
                </div>
              <% end %>
            </div>
          </div>
          <%= if @researcher do %>
            <div class="flex-shrink-0">
              <div class="rounded-lg bg-grey5">
                <img src={@researcher.institution.image} alt={@researcher.institution.name}>
                <div class="flex flex-col gap-3 p-4">
                  <div class="text-title7 font-title7 text-grey1">
                    <%= @researcher.name %>
                  </div>
                  <div class="text-caption font-caption text-grey1">
                    <%= @researcher.job_title %>
                  </div>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      </Area.sheet>
      </Area.content>
    </div>
    """
  end
end
