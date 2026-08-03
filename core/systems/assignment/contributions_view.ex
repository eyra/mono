defmodule Systems.Assignment.ContributionsView do
  use CoreWeb, :embedded_live_view

  require Logger

  alias Frameworks.Pixel.Text
  alias Systems.Assignment

  @decline_modal_id "decline-contribution-modal"

  def dependencies(), do: [:assignment_id, :title]

  def get_model(:not_mounted_at_router, _session, %{assigns: %{assignment_id: assignment_id}}) do
    Assignment.Public.get!(assignment_id, Assignment.Model.preload_graph(:down))
  end

  @impl true
  def mount(:not_mounted_at_router, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_view_model_updated(socket), do: socket

  @impl true
  def handle_info(:confirm_all, %{assigns: %{vm: vm}} = socket) do
    vm
    |> pending_rows()
    |> Enum.map(& &1.participation_id)
    |> Enum.reject(&is_nil/1)
    |> Enum.each(fn id ->
      case Assignment.Public.accept_participation(id) do
        {:ok, _} ->
          :ok

        error ->
          Logger.warning(
            "[ContributionsView] accept_participation #{id} failed: #{inspect(error)}"
          )
      end
    end)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:show_decline_modal, %{participation_id: participation_id} = row}, socket)
      when is_integer(participation_id) do
    modal =
      LiveNest.Modal.prepare_live_component(
        @decline_modal_id,
        Assignment.DeclineContributionForm,
        params: [
          participation_id: participation_id,
          subject_label: subject_label(row)
        ],
        style: :compact
      )

    {:noreply, socket |> present_modal(modal)}
  end

  @impl true
  def handle_info(
        {:submit_decline, %{participation_id: participation_id, reason: reason}},
        socket
      )
      when is_integer(participation_id) do
    socket =
      case Assignment.Public.reject_participation(participation_id, reason) do
        {:ok, _} ->
          socket

        error ->
          Logger.warning(
            "[ContributionsView] reject_participation #{participation_id} failed: #{inspect(error)}"
          )

          Frameworks.Pixel.Flash.push_error(
            socket,
            dgettext("eyra-assignment", "contributions.decline.error")
          )
      end

    {:noreply, socket |> hide_decline_modal()}
  end

  @impl true
  def handle_info(:hide_decline_modal, socket) do
    {:noreply, socket |> hide_decline_modal()}
  end

  defp hide_decline_modal(socket) do
    modal = %LiveNest.Modal{element: %LiveNest.Element{id: @decline_modal_id}}
    hide_modal(socket, modal)
  end

  defp pending_rows(%{sections: sections}) do
    case Enum.find(sections, fn {key, _} -> key == :pending end) do
      {_, %{rows: rows}} -> rows
      _ -> []
    end
  end

  defp subject_label(%{member_public_id: member_public_id}) do
    "#{dgettext("eyra-assignment", "contributions.subject_label")} #{member_public_id}"
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
        <Margin.y id={:page_top} />
        <div data-testid="contributions-view">
          <Text.title2><%= @vm.title %></Text.title2>
          <.spacing value="L" />
          <%= for {{_key, section}, index} <- Enum.with_index(@vm.sections) do %>
            <%= if index > 0 do %>
              <div class="border-t border-grey4 mb-8" />
            <% end %>
            <.live_component
              module={section.module}
              id={section.id}
              rows={section.rows}
              count={section.count}
            />
          <% end %>
        </div>
      </Area.content>
    </div>
    """
  end
end
