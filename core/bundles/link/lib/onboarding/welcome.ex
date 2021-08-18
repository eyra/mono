defmodule Link.Onboarding.Welcome do
  use Surface.LiveComponent

  import CoreWeb.Gettext

  alias EyraUI.Text.{Title2}
  alias EyraUI.Container.{ContentArea, SheetArea}

  prop(user, :any, required: true)

  data title, :any

  def update(%{id: id, user: user}, socket) do
    user.displayname |> IO.inspect(label: "USER DISPLAY NAME")

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
      <ContentArea top_padding="pt-0">
        <SheetArea>
          <div class="flex flex-col items-center">
            <div class="mb-8 sm:mb-16">
              <img src="/images/illustrations/cards.svg" />
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
