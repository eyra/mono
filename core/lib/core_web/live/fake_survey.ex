defmodule CoreWeb.FakeSurvey do
  @moduledoc """
  The home screen.
  """
  use CoreWeb, :live_view
  alias EyraUI.Hero.HeroSmall
  alias EyraUI.Text.{BodyLarge, Title2}
  alias EyraUI.Button.PrimaryButton

  data(redirect_url, :string)

  def mount(%{"redirect_url" => redirect_url}, _session, socket) do
    socket =
      socket
      |> assign(redirect_url: redirect_url)

    {:ok, socket}
  end

  @impl true
  def handle_uri(socket), do: socket

  def render(assigns) do
    ~H"""
      <HeroSmall title="Fake survey" bg_color="bg-grey1"/>

      <ContentArea>
        <MarginY id={{:page_top}} />
        <Title2>Fake survey</Title2>
        <BodyLarge>This fake survey is used to validate the survey tool flow with an external tool.</BodyLarge>
        <Spacing value="M" />
        <PrimaryButton label="Complete survey (go back)" to={{@redirect_url}} bg_color="bg-grey1" />
      </ContentArea>
    """
  end
end
