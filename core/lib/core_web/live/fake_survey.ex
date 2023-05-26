defmodule CoreWeb.FakeSurvey do
  @moduledoc """
  The home screen.
  """
  use CoreWeb, :live_view
  alias Frameworks.Pixel.Hero
  alias Frameworks.Pixel.Text
  alias Frameworks.Pixel.Button

  def mount(%{"id" => id}, _session, socket) do
    redirect_url = "/task/#{id}/callback"

    socket =
      socket
      |> assign(redirect_url: redirect_url)

    {:ok, socket}
  end

  @impl true
  def handle_uri(socket), do: socket

  # data(redirect_url, :string)
  @impl true
  def render(assigns) do
    ~H"""
    <div>
    <Hero.small title="Fake survey" bg_color="bg-grey1" />

    <Area.content>
      <Margin.y id={:page_top} />
      <Text.title2>Fake survey</Text.title2>
      <Text.body_large>This fake survey is used to validate the survey tool flow with an external tool.</Text.body_large>
      <.spacing value="M" />
      <Button.primary label="Complete survey (go back)" to={@redirect_url} bg_color="bg-grey1" />
      </Area.content>
    </div>
    """
  end
end
