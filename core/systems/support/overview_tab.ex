defmodule Systems.Support.OverviewTab do
  @moduledoc false
  use CoreWeb, :live_component

  import Frameworks.Pixel.Content

  alias Core.ImageHelpers
  alias CoreWeb.UI.Area
  alias CoreWeb.UI.Timestamp
  alias Systems.Support

  @impl true
  def update(%{id: id, tickets: tickets}, socket) do
    items = Enum.map(tickets, &to_view_model(&1, socket))

    {
      :ok,
      socket
      |> assign(id: id)
      |> assign(items: items)
    }
  end

  defp to_view_model(
         %Support.TicketModel{
           updated_at: updated_at,
           title: title,
           user: %{profile: %{fullname: subtitle, photo_url: photo_url}, features: features}
         } = ticket,
         _socket
       ) do
    gender = gender(features)

    quick_summery =
      updated_at
      |> Timestamp.apply_timezone()
      |> Timestamp.humanize()

    image = %{
      type: :avatar,
      info: ImageHelpers.get_photo_url(%{photo_url: photo_url, gender: gender})
    }

    %{
      path: ~p"/support/ticket/#{ticket.id}",
      title: title,
      subtitle: subtitle,
      quick_summary: quick_summery,
      tag: Support.TicketModel.tag(ticket),
      image: image
    }
  end

  defp gender(%{gender: gender}), do: gender
  defp gender(_), do: :x

  attr(:tickets, :list, required: true)
  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Margin.y id={:page_top} />

      <%= if Enum.empty?(@items) do %>
        <div class="h-full">
          <Margin.y id={:page_top} />
          <div class="flex flex-col items-center w-full h-full">
            <div class="flex-grow" />
            <div class="flex-none">
              <img src={~p"/images/illustrations/zero-todo.svg"} id="zero-todos" alt="All done">
            </div>
            <div class="flex-grow" />
          </div>
        </div>
      <% else %>
        <Area.content>
          <.list items={@items} />
        </Area.content>
      <% end %>
    </div>
    """
  end
end
