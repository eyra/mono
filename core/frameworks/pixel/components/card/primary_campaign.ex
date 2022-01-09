defmodule Frameworks.Pixel.Card.PrimaryCampaign do
  @moduledoc """
  A large eye-catcher meant to call a user into taking an action.
  """
  use Surface.Component
  alias Frameworks.Pixel.Card.Campaign

  prop(path_provider, :any, required: true)
  prop(card, :any, required: true)
  prop(click_event_name, :string)
  prop(click_event_data, :string)

  def render(assigns) do
    ~F"""
    <Campaign

      path_provider={@path_provider}
      card={@card}
      click_event_data={@click_event_data}
      click_event_name={@click_event_name}
    />
    """
  end
end
