defmodule EyraUI.Card.PrimaryStudy do
  @moduledoc """
  A large eye-catcher meant to call a user into taking an action.
  """
  use Surface.Component
  alias EyraUI.Card.Study

  prop(conn, :any, required: true)
  prop(path_provider, :any, required: true)
  prop(card, :any, required: true)
  prop(click_event_name, :string)
  prop(click_event_data, :string)

  def render(assigns) do
    ~H"""
    <Study
      conn={{@conn}}
      path_provider={{@path_provider}}
      card={{@card}}
      click_event_data={{@click_event_data}}
      click_event_name={{@click_event_name}}
    />
    """
  end
end
