defmodule Systems.Assignment.ContributionsConfirmedView do
  use Phoenix.LiveComponent
  use Gettext, backend: CoreWeb.Gettext

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
    <div data-testid="contributions-confirmed">
      <div class="flex items-baseline gap-2 mb-6">
        <Text.title3 margin="">
          <%= @labels.overview_heading %>
        </Text.title3>
        <span class="text-title3 font-title3 text-primary" data-testid="contributions-confirmed-count">
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
      >
        <:row :let={row}>
          <.confirmed_row row={row} labels={@labels} />
        </:row>
        <:empty>
          <div
            class="text-bodymedium font-body text-grey2 pb-6"
            data-testid="contributions-confirmed-empty"
          >
            <%= @labels.overview_empty %>
          </div>
        </:empty>
      </.live_component>
    </div>
    """
  end

  defp haystack(%{member_public_id: pid}), do: to_string(pid)

  attr(:row, :map, required: true)
  attr(:labels, :map, required: true)

  defp confirmed_row(assigns) do
    ~H"""
    <tr
      class="text-bodymedium font-body"
      data-testid={"contributions-confirmed-row-#{@row.reward_id}"}
    >
      <td class="py-3">
        <%= @labels.subject_label %>
        <%= @row.member_public_id %>
      </td>
    </tr>
    """
  end

  defp labels do
    %{
      overview_heading: dgettext("eyra-assignment", "contributions.overview.heading"),
      overview_empty: dgettext("eyra-assignment", "contributions.overview.empty"),
      subject_label: dgettext("eyra-assignment", "contributions.subject_label"),
      search_placeholder: dgettext("eyra-assignment", "contributions.search.placeholder"),
      search_no_match: dgettext("eyra-assignment", "contributions.search.no_match")
    }
  end
end
