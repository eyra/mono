defmodule Systems.Assignment.ContributionsDeclinedView do
  use Phoenix.LiveComponent
  use Gettext, backend: CoreWeb.Gettext

  alias CoreWeb.UI.Timestamp
  alias Frameworks.Pixel.List, as: PixelList
  alias Frameworks.Pixel.Text

  @impl true
  def update(%{id: id, rows: rows, count: count}, socket) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        rows: rows,
        count: count,
        labels: labels()
      )
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div data-testid="contributions-declined">
      <div class="flex items-baseline gap-2 mb-6">
        <Text.title3 margin="">
          <%= @labels.heading %>
        </Text.title3>
        <span class="text-title3 font-title3 text-primary" data-testid="contributions-declined-count">
          <%= @count %>
        </span>
      </div>

      <.live_component
        module={PixelList}
        id={"#{@id}-list"}
        rows={@rows}
        page_size={7}
        haystack_fn={&haystack/1}
        placeholder={@labels.search_placeholder}
        no_match={@labels.search_no_match}
        stretch={true}
      >
        <:row :let={row}>
          <.declined_row row={row} labels={@labels} />
        </:row>
      </.live_component>
    </div>
    """
  end

  defp haystack(%{member_public_id: pid, rejection_reason: reason}) do
    "#{pid} #{reason}"
  end

  attr(:row, :map, required: true)
  attr(:labels, :map, required: true)

  defp declined_row(assigns) do
    ~H"""
    <tr
      class="text-bodymedium font-body"
      data-testid={"contributions-declined-row-#{@row.participation_id}"}
    >
      <td class="py-3 pr-8 whitespace-nowrap">
        <%= @labels.subject_label %>
        <%= @row.member_public_id %>
      </td>
      <td
        class="py-3 pr-8 text-grey2 whitespace-nowrap"
        data-testid={"contributions-declined-date-#{@row.participation_id}"}
      >
        <%= format_date(@row.rejected_at) %>
      </td>
      <td
        class="py-3 text-delete w-full max-w-0"
        data-testid={"contributions-declined-reason-#{@row.participation_id}"}
      >
        <div class="relative group cursor-help">
          <div class="truncate">
            <%= @row.rejection_reason %>
          </div>
          <div class="pointer-events-none opacity-0 group-hover:opacity-100 transition-opacity duration-150 absolute z-10 left-0 top-full mt-1 max-w-md px-5 py-4 rounded bg-grey1 text-white text-bodymedium font-body shadow-lg whitespace-normal">
            <%= @row.rejection_reason %>
          </div>
        </div>
      </td>
    </tr>
    """
  end

  defp format_date(nil), do: ""
  defp format_date(datetime), do: Timestamp.humanize(datetime, capitalize: true)

  defp labels do
    %{
      heading: dgettext("eyra-assignment", "contributions.declined.heading"),
      subject_label: dgettext("eyra-assignment", "contributions.subject_label"),
      search_placeholder: dgettext("eyra-assignment", "contributions.search.placeholder"),
      search_no_match: dgettext("eyra-assignment", "contributions.search.no_match")
    }
  end
end
