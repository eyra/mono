defmodule Systems.Assignment.FinishedView do
  use CoreWeb, :live_component

  use Gettext, backend: CoreWeb.Gettext

  @impl true
  def update(
        %{
          title: title,
          body: body,
          show_illustration: show_illustration,
          retry_button: retry_button,
          redirect_button: redirect_button
        },
        socket
      ) do
    {
      :ok,
      socket
      |> assign(
        title: title,
        body: body,
        show_illustration: show_illustration,
        retry_button: retry_button,
        redirect_button: redirect_button
      )
    }
  end

  def handle_event("retry", _, socket) do
    {:noreply, socket |> send_event(:parent, "retry")}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div class="flex flex-row w-full h-full">
        <div class="flex-grow" />
        <div class="flex flex-col gap-4 sm:gap-8 items-center w-full h-full px-6">
          <div class="flex-grow" />
          <Text.title1 margin=""><%= @title %></Text.title1>
          <div>
            <Text.body_large align="text-center">
              <%= @body %>
            </Text.body_large>
            <div :if={@show_illustration} class="flex flex-col items-center w-full pt-4">
              <img class="block w-[220px] h-[220px] object-cover" src={~p"/images/illustrations/finished.svg"} id="zero-todos" alt="All tasks done">
            </div>
          </div>

          <div class="flex flex-row items-center gap-6">
            <Button.dynamic :if={@retry_button} {@retry_button} />
            <Button.dynamic :if={@redirect_button} {@redirect_button} />
          </div>
          <div class="flex-grow" />
        </div>
        <div class="flex-grow" />
      </div>
    """
  end
end
