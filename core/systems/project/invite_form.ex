defmodule Systems.Project.InviteForm do
  use CoreWeb.LiveForm

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
      <Margin.y id={:page_top} />
        <Text.title2><%= dgettext("eyra-project", "invite.title")  %></Text.title2>
      </Area.content>
    </div>
    """
  end
end
