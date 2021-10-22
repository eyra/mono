defmodule Link.Onboarding.Welcome do
  use CoreWeb.UI.LiveComponent

  alias EyraUI.Text.{Title2}

  prop(user, :any, required: true)

  data(title, :any)

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

  def render(assigns) do
    ~H"""
      <ContentArea>
        <MarginY id={{:page_top}} />
        <SheetArea>
          <div class="flex flex-col items-center">
            <div class="mb-8 sm:mb-16">
              <img src="/images/illustrations/cards.svg" alt="" />
            </div>
            <Title2>{{ @title }}</Title2>
            <div class="sm:px-2 text-center text-bodymedium sm:text-bodylarge font-body">
              {{dgettext("link-ui", "onboarding.welcome.description")}}
            </div>
          </div>
        </SheetArea>
      </ContentArea>
    """
  end
end
