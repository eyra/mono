defmodule Systems.Home.ParticipatedView do
  use CoreWeb, :live_component

  alias Frameworks.Pixel.Image
  alias Frameworks.Pixel.Text
  alias Systems.Assignment.CurrencyHelpers

  @impl true
  def update(%{content_items: content_items}, socket) do
    {
      :ok,
      socket |> assign(content_items: content_items)
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="border-2 border-grey4 rounded p-6" data-testid="participated">
      <Text.title2 margin="">
        <%= dgettext("eyra-home", "participated.title") %>
        <span class="text-primary"> <%= Enum.count(@content_items) %></span>
      </Text.title2>
      <.spacing value="M" />

      <div class="flex flex-col divide-y divide-grey4">
        <%= for item <- @content_items do %>
          <.row item={item} />
        <% end %>
      </div>
    </div>
    """
  end

  attr(:item, :map, required: true)

  defp row(assigns) do
    ~H"""
    <a
      href={@item.path}
      class="flex flex-row items-center gap-4 py-4 first:pt-0 last:pb-0 hover:bg-grey6 -mx-2 px-2 rounded"
      data-testid="participated-row"
    >
      <div class="flex-1 min-w-0">
        <div class="text-title5 font-title5 text-grey1 truncate">
          <%= @item.title %>
        </div>
        <%= if @item.subtitle do %>
          <div class="text-bodysmall font-body text-grey2 truncate">
            <%= @item.subtitle %>
          </div>
        <% end %>
      </div>

      <div class="flex flex-col items-end gap-1 shrink-0">
        <div class="text-bodymedium font-body text-grey1">
          <%= dgettext("eyra-home", "participated.reward.label") %>
          <span class="text-title6 font-title6">
            <%= CurrencyHelpers.format_cents(@item.reward_cents) %>
          </span>
        </div>
        <.status_pill status={@item.reward_status} />
      </div>

      <div class="w-24 h-16 rounded overflow-hidden bg-grey4 shrink-0">
        <%= if @item.image_info do %>
          <Image.blurhash id={"participated-#{:erlang.phash2(@item.path)}"} image={@item.image_info} />
        <% end %>
      </div>
    </a>
    """
  end

  attr(:status, :atom, default: nil)

  defp status_pill(%{status: :awaiting} = assigns) do
    ~H"""
    <span class="inline-flex items-center px-3 py-0.5 rounded-full text-white text-label font-label bg-warning">
      <%= dgettext("eyra-home", "participated.status.awaiting") %>
    </span>
    """
  end

  defp status_pill(%{status: :approved} = assigns) do
    ~H"""
    <span class="inline-flex items-center px-3 py-0.5 rounded-full text-white text-label font-label bg-success">
      <%= dgettext("eyra-home", "participated.status.approved") %>
    </span>
    """
  end

  defp status_pill(%{status: :rejected} = assigns) do
    ~H"""
    <span class="inline-flex items-center px-3 py-0.5 rounded-full text-white text-label font-label bg-delete">
      <%= dgettext("eyra-home", "participated.status.rejected") %>
    </span>
    """
  end

  defp status_pill(assigns) do
    ~H"""
    <span></span>
    """
  end
end
