defmodule Systems.Support.OverviewTab do
  use CoreWeb.UI.LiveComponent

  alias Core.ImageHelpers
  alias CoreWeb.UI.ContentList
  alias CoreWeb.UI.Container.ContentArea

  alias Systems.Support

  prop(props, :map)

  data(items, :list)

  def update(%{id: id, props: %{tickets: tickets}}, socket) do
    items =
      tickets
      |> Enum.map(&to_view_model(&1, socket))

    {
      :ok,
      socket
      |> assign(id: id)
      |> assign(items: items)
    }
  end

  defp to_view_model(
         %Support.TicketModel{
           id: id,
           updated_at: updated_at,
           title: title,
           user: %{
             profile: %{
               fullname: subtitle,
               photo_url: photo_url
             },
             features: %{
               gender: gender
             }
           }
         } = ticket,
         socket
       ) do
    quick_summery =
      updated_at
      |> CoreWeb.UI.Timestamp.apply_timezone()
      |> CoreWeb.UI.Timestamp.humanize()

    image = %{
      type: :avatar,
      info: ImageHelpers.get_photo_url(%{photo_url: photo_url, gender: gender})
    }

    %{
      path: Routes.live_path(socket, Support.TicketPage, id),
      title: title,
      subtitle: subtitle,
      quick_summary: quick_summery,
      tag: Support.TicketModel.tag(ticket),
      image: image
    }
  end

  def render(assigns) do
    ~F"""
      <div>
      <MarginY id={:page_top} />

      <div :if={Enum.empty?(@items)} class="h-full">
          <MarginY id={:page_top} />
          <div class="flex flex-col items-center w-full h-full">
            <div class="flex-grow"></div>
            <div class="flex-none">
              <img src="/images/illustrations/zero-todo.svg" id="zero-todos" alt="All done" />
            </div>
            <div class="flex-grow"></div>
          </div>
        </div>

        <ContentArea>
          <ContentList items={@items} />
        </ContentArea>
      </div>
    """
  end
end
