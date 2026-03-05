defmodule CoreWeb.FakeQualtrics do
  @moduledoc """
  The home screen.
  """
  use CoreWeb, :live_view

  alias Frameworks.Pixel.Button
  alias Frameworks.Pixel.Text

  @impl true
  def mount(%{"re" => redirect_url}, _session, socket) do
    socket = assign(socket, redirect_url: redirect_url)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full h-full">
      <div class="bg-grey1 p-12">
        <Text.title1 margin="" color="text-white">Qualtrics emulator</Text.title1>
      </div>
      <Area.content>
        <Margin.y id={:page_top} />
        <Text.title2>Questionnaire</Text.title2>
        <Text.body_large>This page is used to validate the questionnaire roundtrip.</Text.body_large>
        <.spacing value="M" />
        <Button.primary label="Finish" to={@redirect_url} bg_color="bg-grey1" />
      </Area.content>
    </div>
    """
  end
end
