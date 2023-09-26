defmodule Systems.Privacy.Form do
  use CoreWeb.LiveForm

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
        <Margin.y id={:page_top} />
        <Text.title2><%= dgettext("eyra-privacy", "form.title")  %></Text.title2>
      </Area.content>
    </div>
    """
  end
end
