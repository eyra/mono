defmodule Systems.Home.ParticipatedView do
  use CoreWeb, :live_component

  alias Frameworks.Pixel.Text
  alias Systems.Assignment.CurrencyHelpers

  @impl true
  def update(%{content_items: content_items, labels: labels}, socket) do
    {
      :ok,
      socket |> assign(content_items: content_items, labels: labels)
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="border-2 border-grey4 rounded p-4 md:p-6" data-testid="participated">
      <Text.title2 margin="">
        <%= @labels.title %>
        <span class="text-primary"> <%= Enum.count(@content_items) %></span>
      </Text.title2>
      <.spacing value="M" />

      <div class="flex flex-col divide-y divide-grey4">
        <%= for item <- @content_items do %>
          <.row item={item} labels={@labels} />
        <% end %>
      </div>
    </div>
    """
  end

  attr(:item, :map, required: true)
  attr(:labels, :map, required: true)

  defp row(assigns) do
    ~H"""
    <a
      href={@item.path}
      class="flex flex-row items-start gap-3 md:gap-4 py-4 first:pt-0 last:pb-0 hover:bg-grey6 -mx-2 px-2 rounded"
      data-testid="participated-row"
    >
      <div class="flex-1 min-w-0">
        <div class="text-title5 font-title5 text-grey1 break-words line-clamp-2">
          <%= @item.title %>
        </div>
        <%= if @item.subtitle do %>
          <div class="mt-2 text-bodysmall font-body text-grey2 break-words line-clamp-2">
            <%= @item.subtitle %>
          </div>
        <% end %>
        <div class="mt-1 lg:hidden flex flex-wrap items-center gap-x-2 gap-y-1">
          <.status_pill status={@item.reward_status} labels={@labels} />
          <.reward_label labels={@labels} reward_cents={@item.reward_cents} />
        </div>
      </div>

      <div class="hidden lg:flex flex-col items-end gap-1 shrink-0">
        <.status_pill status={@item.reward_status} labels={@labels} />
        <.reward_label labels={@labels} reward_cents={@item.reward_cents} />
      </div>
    </a>
    """
  end

  attr(:labels, :map, required: true)
  attr(:reward_cents, :integer, required: true)

  defp reward_label(assigns) do
    ~H"""
    <span class="text-bodymedium font-body text-grey1 whitespace-nowrap">
      <%= @labels.reward_label %>
      <span class="text-title6 font-title6">
        <%= CurrencyHelpers.format_cents(@reward_cents) %>
      </span>
    </span>
    """
  end

  attr(:status, :atom, default: nil)
  attr(:labels, :map, required: true)

  defp status_pill(%{status: :awaiting} = assigns) do
    ~H"""
    <span class="inline-flex items-center px-3 py-1 rounded-full text-white text-label font-label bg-warning">
      <%= @labels.status.awaiting %>
    </span>
    """
  end

  defp status_pill(%{status: :approved} = assigns) do
    ~H"""
    <span class="inline-flex items-center px-3 py-1 rounded-full text-white text-label font-label bg-success">
      <%= @labels.status.approved %>
    </span>
    """
  end

  defp status_pill(%{status: :rejected} = assigns) do
    ~H"""
    <span class="inline-flex items-center px-3 py-1 rounded-full text-white text-label font-label bg-delete">
      <%= @labels.status.rejected %>
    </span>
    """
  end

  defp status_pill(assigns) do
    ~H"""
    <span></span>
    """
  end
end
