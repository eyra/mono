defmodule LinkWeb.TestLive do
  # If you generated an app with mix phx.new --live,
  # the line below would be: use MyAppWeb, :live_view
  use Phoenix.LiveView

  def render(assigns) do
    ~L"""
    Current temperature: <%= @temperature %>
    """
  end

  def mount(_params, _session, socket) do
    temperature = "10"
    {:ok, assign(socket, :temperature, temperature)}
  end
end
