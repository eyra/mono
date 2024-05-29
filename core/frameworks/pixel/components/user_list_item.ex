defmodule Frameworks.Pixel.UserListItem do
  @moduledoc """
    User list item
  """
  use CoreWeb, :pixel

  alias Core.ImageHelpers

  alias Frameworks.Pixel.Button

  attr(:user, :map, required: true)
  attr(:action_button, :map, required: true)

  def small(assigns) do
    ~H"""
    <div class="flex flex-row items-center gap-3 w-full">
      <div class="flex-shrink-0">
        <img
          src={ImageHelpers.get_photo_url(@user.profile)}
          class="rounded-full w-8 h-8 border-2 border-grey4 border-grey4"
          alt=""
        />
      </div>
      <div class="flex-grow font-label text-label text-grey1 mt-2px">
        <%= Systems.Account.User.label(@user) %>
      </div>
      <div class="flex-wrap flex-shrink-0">
        <Button.dynamic {@action_button} />
      </div>
    </div>
    """
  end
end
