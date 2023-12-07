defmodule Systems.Assignment.TicketView do
  use CoreWeb, :html

  import CoreWeb.Gettext
  alias Frameworks.Pixel.Text

  attr(:public_id, :string, required: true)

  def normal(assigns) do
    ~H"""
    <div class="flex flex-row gap-12 rounded-lg shadow-floating p-8 h-full bg-tertiary">
      <Text.title4><%= dgettext("eyra-assignment", "ticket.title") %></Text.title4>
      <Text.title4><%= @public_id %></Text.title4>
    </div>
    """
  end
end
