defmodule CoreWeb.DataDonation.PromotionPlugin do

  alias Core.Promotions.CallToAction
  alias Core.Promotions.CallToAction.Target
  alias CoreWeb.Promotion.Plugin

  @behaviour Plugin

  @impl Plugin
  def call_to_action() do
    %CallToAction{
      label: "Aap",
      target: %Target{type: :event, value: :apply}
    }
  end

  @impl Plugin
  def handle_event(:apply, socket) do
    {:ok, socket}
  end

  @impl Plugin
  def handle_event(_event, _socket) do
    {:error, "Unknown event"}
  end

end
