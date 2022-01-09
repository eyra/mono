defmodule CoreWeb.UI.UserListItemSmall do
  @moduledoc """
    User list item
  """
  use CoreWeb.UI.Component

  alias Core.ImageHelpers

  prop(user, :map, required: true)
  prop(action_button, :map, required: true)

  def render(assigns) do
    ~F"""
      <div class="flex flex-row items-center gap-3 w-full">
        <div class="flex-shrink-0">
          <img src={ImageHelpers.get_photo_url(@user.profile)} class="rounded-full w-8 h-8 border-2 border-grey4 border-grey4" alt="" />
        </div>
        <div class="flex-grow font-label text-label text-grey1 mt-2px">
          {@user.profile.fullname}
        </div>
        <div class="flex-wrap flex-shrink-0">
          <DynamicButton vm={@action_button} />
        </div>
      </div>
    """
  end
end
