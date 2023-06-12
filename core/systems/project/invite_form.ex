defmodule Systems.Project.InviteForm do
  use CoreWeb.LiveForm

  @impl true
  def update(%{url: url}, socket) do
    {
      :ok,
      socket
      |> assign(url: url)
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
      <Margin.y id={:page_top} />
        <Text.title2><%= dgettext("eyra-project", "invite.title")  %></Text.title2>
        <Text.title3><%= dgettext("eyra-project", "direct.invite.title")  %></Text.title3>
        <Text.body><%= dgettext("eyra-project", "direct.invite.description")  %></Text.body>
        <.spacing value="XS" />
        <div class="flex flex-row gap-6 items-center">
          <div class="flex-wrap">
            <Text.body_medium><span class="break-all"><%= @url %></span></Text.body_medium>
          </div>
          <div class="flex-wrap flex-shrink-0 mt-1">
            <div id="copy-redirect-url" class="cursor-pointer" phx-hook="Clipboard" data-text={@url}>
              <Button.Face.label_icon
                label={dgettext("eyra-ui", "copy.button")}
                icon={:clipboard_primary}
              />
            </div>
          </div>
        </div>
        <.spacing value="M" />
        <Text.title3><%= dgettext("eyra-project", "campaign.invite.title")  %></Text.title3>
        <Text.body>TBD..</Text.body>
      </Area.content>
    </div>
    """
  end
end
