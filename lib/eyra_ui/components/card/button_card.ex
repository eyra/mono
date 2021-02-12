defmodule EyraUI.Card.ButtonCard do
  @moduledoc """
  A large eye-catcher meant to call a user into taking an action.
  """
  use Surface.Component
  alias LinkWeb.Router.Helpers, as: Routes

  prop socket, :map, required: true
  prop title, :string, required: true
  prop path, :string, required: true

  def render(assigns) do
    ~H"""
    <div onclick="location.href='{{@path}}';" class="bg-transparent h-full w-full rounded-md border-2 border-grey3 border-dashed hover:border-grey6 hover:bg-grey6 cursor-pointer">
      <div class="flex flex-col items-center justify-center h-full w-full pl-11 pr-11 md:pl-20 md:pr-20 lg:pl-10 lg:pr-10 pt-16 pb-16">
        <div class="mb-6">
            <img src={{Routes.static_path(@socket, "/images/plus-primary.svg")}}/>
        </div>
        <div class="w-full mb-9 text-grey1 text-title5 font-title5 lg:text-title4 lg:font-title4 text-center">
            {{@title}}
        </div>
      </div>
    </div>
    """
  end
end
