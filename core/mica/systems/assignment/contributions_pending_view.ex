defmodule Systems.Assignment.ContributionsPendingView do
  use Phoenix.LiveComponent
  use Gettext, backend: CoreWeb.Gettext

  alias Frameworks.Pixel.Button
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
  def handle_event("confirm_all", _, socket) do
    send(self(), :confirm_all)
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "expand_decline",
        %{"item" => participation_id_str},
        %{assigns: %{rows: rows}} = socket
      ) do
    participation_id = String.to_integer(participation_id_str)

    case Enum.find(rows, &(&1.participation_id == participation_id)) do
      nil ->
        {:noreply, socket}

      row ->
        send(self(), {:show_decline_modal, row})
        {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-[500px]" data-testid="contributions-pending">
      <div class="flex items-baseline gap-2 mb-6">
        <Text.title3 margin="">
          <%= @labels.waiting_heading %>
        </Text.title3>
        <span class="text-title3 font-title3 text-primary" data-testid="contributions-pending-count">
          <%= @count %>
        </span>
      </div>

      <%= if @count > 0 do %>
        <div class="mb-6">
          <Button.dynamic {confirm_button(@labels, @myself)} />
        </div>
      <% end %>

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
          <.pending_row row={row} labels={@labels} myself={@myself} />
        </:row>
        <:empty>
          <div
            class="text-bodymedium font-body text-grey2 pb-6"
            data-testid="contributions-pending-empty"
          >
            <%= @labels.waiting_empty %>
          </div>
        </:empty>
      </.live_component>
    </div>
    """
  end

  defp confirm_button(labels, myself) do
    %{
      action: %{type: :send, event: "confirm_all", target: myself},
      face: %{type: :primary, label: labels.confirm_all},
      testid: "confirm-all-button"
    }
  end

  defp haystack(%{member_public_id: pid}), do: to_string(pid)

  attr(:row, :map, required: true)
  attr(:labels, :map, required: true)
  attr(:myself, :any, required: true)

  defp pending_row(assigns) do
    ~H"""
    <tr
      class="text-bodymedium font-body"
      data-testid={"pending-row-#{@row.participation_id}"}
    >
      <td class="py-3 pr-8">
        <%= @labels.subject_label %>
        <%= @row.member_public_id %>
      </td>
      <td
        class={"py-3 pr-8 " <> tasks_class(@row)}
        data-testid={"tasks-finished-#{@row.participation_id}"}
      >
        <%= tasks_label(@row, @labels) %>
      </td>
      <td class="py-3">
        <Button.dynamic
          action={%{
            type: :send,
            event: "expand_decline",
            item: to_string(@row.participation_id),
            target: @myself
          }}
          face={%{
            type: :plain,
            icon: :reject,
            icon_align: :left,
            label: @labels.decline_link
          }}
          testid={"decline-#{@row.participation_id}"}
        />
      </td>
    </tr>
    """
  end

  defp tasks_class(%{completed_task_count: c, total_task_count: t}) when c >= t and t > 0,
    do: "text-grey2"

  defp tasks_class(_), do: "text-warning"

  defp tasks_label(%{completed_task_count: c, total_task_count: t}, labels) when c >= t and t > 0,
    do: labels.tasks_all_finished

  defp tasks_label(%{completed_task_count: c, total_task_count: t}, _labels) do
    dngettext(
      "eyra-assignment",
      "contributions.tasks_finished.one",
      "contributions.tasks_finished.other",
      c,
      count: c,
      total: t
    )
  end

  defp labels do
    %{
      waiting_heading: dgettext("eyra-assignment", "contributions.waiting.heading"),
      waiting_empty: dgettext("eyra-assignment", "contributions.waiting.empty"),
      confirm_all: dgettext("eyra-assignment", "contributions.confirm_all.button"),
      subject_label: dgettext("eyra-assignment", "contributions.subject_label"),
      decline_link: dgettext("eyra-assignment", "contributions.decline.link"),
      tasks_all_finished: dgettext("eyra-assignment", "contributions.all_tasks_finished"),
      search_placeholder: dgettext("eyra-assignment", "contributions.search.placeholder"),
      search_no_match: dgettext("eyra-assignment", "contributions.search.no_match")
    }
  end
end
