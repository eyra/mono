defmodule Systems.Admin.AccountView do
  use CoreWeb, :live_component

  alias Frameworks.Pixel.Text

  # Initial update
  @impl true
  def update(
        %{
          id: id,
          user: user,
          creators: creators
        },
        socket
      ) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        user: user,
        creators: creators
      )
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
        <Margin.y id={:page_top} />
        <Text.title2><%= dgettext("eyra-admin", "account.title") %></Text.title2>

      </Area.content>
    </div>
    """
  end
end
