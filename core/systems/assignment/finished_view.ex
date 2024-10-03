defmodule Systems.Assignment.FinishedView do
  use CoreWeb, :live_component

  import CoreWeb.Gettext

  @impl true
  def update(_, socket) do
    body = dgettext("eyra-assignment", "finished_view.body")

    {
      :ok,
      socket
      |> assign(body: body)
      |> update_retry_button()
    }
  end

  defp update_retry_button(socket) do
    retry_button = %{
      action: %{type: :send, event: "retry"},
      face: %{
        type: :plain,
        icon: :forward,
        label: dgettext("eyra-assignment", "retry.button")
      }
    }

    assign(socket, retry_button: retry_button)
  end

  def handle_event("retry", _, socket) do
    {:noreply, socket |> send_event(:parent, "retry")}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div class="flex flex-row w-full h-full">
        <div class="flex-grow" />
        <div class="flex flex-col gap-8 items-center w-full h-full">
          <div class="flex-grow" />
          <Text.title1 margin="">Done</Text.title1>
          <Text.body_large><%= @body %></Text.body_large>
          <div class="flex flex-col items-center w-full pt-4">
            <div class="flex-none">
              <img src={~p"/images/illustrations/finished.svg"} id="zero-todos" alt="All tasks done">
            </div>
          </div>
          <div class="pb-4">
            <Button.dynamic {@retry_button} />
          </div>
          <div class="flex-grow" />
        </div>
        <div class="flex-grow" />
      </div>
    """
  end
end
