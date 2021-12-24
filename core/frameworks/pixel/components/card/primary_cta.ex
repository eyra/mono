defmodule Frameworks.Pixel.Card.PrimaryCTA do
  @moduledoc """
  A large eye-catcher meant to call a user into taking an action.
  """
  use Surface.Component
  alias Surface.Components.LiveRedirect
  alias Frameworks.Pixel.Card.Card

  prop(title, :string, required: true)
  prop(button_label, :string, required: true)
  prop(to, :string, required: true)
  prop(button_bg_color, :css_class, default: "bg-white")

  def render(assigns) do
    ~F"""
    <Card bg_color="bg-grey1" id="PrimaryCTA">
      <#template slot="title">
        <div class="text-white text-title5 font-title5 lg:text-title3 lg:font-title3">
            {@title}
        </div>
      </#template>
      <div class="mt-6 lg:mt-8">
          <div class="flex items-center">
              <div class="flex-wrap">
                  <LiveRedirect to={@to} >
                      <div class={"flex", "items-center", "active:opacity-80", "focus:outline-none", "pl-4", "pr-4", "h-48px", "font-button", "text-button", "text-primary", "tracker-widest", "rounded",
                                  @button_bg_color}>
                          <div>{@button_label}</div>
                      </div>
                  </LiveRedirect>
              </div>
              <div class="flex-grow"></div>
          </div>
      </div>
    </Card>
    """
  end
end
