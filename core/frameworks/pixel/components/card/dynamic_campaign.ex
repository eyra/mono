defmodule Frameworks.Pixel.Card.DynamicCampaign do
  use Frameworks.Pixel.Component

  alias Frameworks.Pixel.Card.{PrimaryCampaign, SecondaryCampaign}

  prop(path_provider, :any, required: true)
  prop(card, :any, required: true)
  prop(click_event_name, :string)
  prop(click_event_data, :string)
  prop(left_actions, :list, default: [])
  prop(right_actions, :list, default: [])

  defp campaign(%{type: :primary}), do: PrimaryCampaign
  defp campaign(_), do: SecondaryCampaign

  def render(assigns) do
    ~F"""
      <Surface.Components.Dynamic.LiveComponent
        id={@card.id}
        module={campaign(@card)}
        card={@card}
        path_provider={@path_provider}
        click_event_name={@click_event_name}
        click_event_data={@click_event_data}
      />
    """
  end
end
