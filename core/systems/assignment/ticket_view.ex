defmodule Systems.Assignment.TicketView do
  use Frameworks.Pixel.Component

  import CoreWeb.Gettext

  alias Frameworks.Pixel.Text.Title4

  prop(public_id, :string, required: true)

  def render(assigns) do
    ~F"""
    <div class="flex flex-row gap-12 rounded-lg shadow-2xl p-8 h-full bg-tertiary">
      <Title4>{dgettext("eyra-assignment", "ticket.title") }</Title4>
      <Title4>#{@public_id}</Title4>
    </div>
    """
  end
end
