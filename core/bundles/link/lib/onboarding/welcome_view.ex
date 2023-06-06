defmodule Link.Onboarding.WelcomeView do
  use CoreWeb, :live_component

  alias Frameworks.Pixel.Text
  @impl true
  def update(%{id: id, props: %{user: user}}, socket) do
    title = dgettext("link-ui", "onboarding.welcome.title", member: user.displayname || "")

    {
      :ok,
      socket
      |> assign(id: id)
      |> assign(user: user)
      |> assign(title: title)
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
      <Margin.y id={:page_top} />
      <Area.sheet>
        <div class="flex flex-col items-center">
          <div class="mb-8 sm:mb-16">
            <img src="/images/illustrations/cards.svg" alt="">
          </div>
          <Text.title2><%= @title %></Text.title2>
          <div class="sm:px-2 text-center text-bodymedium sm:text-bodylarge font-body">
            <%= dgettext("link-ui", "onboarding.welcome.description") %>
          </div>
        </div>
      </Area.sheet>
      </Area.content>
    </div>
    """
  end
end
