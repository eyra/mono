defmodule Systems.Assignment.AffiliateView do
  use CoreWeb, :live_component

  alias Systems.Affiliate

  @impl true
  def update(
        %{
          id: id,
          assignment: assignment,
          title: title
        },
        socket
      ) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        assignment: assignment,
        title: title
      )
      |> compose_child(:affiliate)
    }
  end

  @impl true
  def compose(:affiliate, %{assignment: %{affiliate: affiliate}}) do
    %{
      module: Affiliate.Form,
      params: %{
        affiliate: affiliate
      }
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
        <Margin.y id={:page_top} />
        <Text.title2><%= @title %></Text.title2>
        <.spacing value="L" />
        <Text.body><%= dgettext("eyra-assignment", "affiliate.body") %></Text.body>
        <.spacing value="M" />
        <.child name={:affiliate} fabric={@fabric} />
      </Area.content>
    </div>
    """
  end
end
