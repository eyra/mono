defmodule Systems.Assignment.FinishedView do
  use CoreWeb, :live_component

  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Affiliate

  @impl true
  def update(%{title: title, user: user, affiliate: affiliate}, socket) do
    redirect_url = Affiliate.Public.redirect_url(affiliate, user)
    body_default = dgettext("eyra-assignment", "finished_view.body")
    body_redirect = dgettext("eyra-assignment", "finished_view.body.redirect")

    {
      :ok,
      socket
      |> assign(
        title: title,
        body_default: body_default,
        body_redirect: body_redirect,
        redirect_url: redirect_url
      )
      |> update_retry_button()
      |> update_redirect_button()
    }
  end

  defp update_redirect_button(%{assigns: %{redirect_url: nil}} = socket) do
    socket |> assign(redirect_button: nil)
  end

  defp update_redirect_button(%{assigns: %{redirect_url: redirect_url}} = socket) do
    redirect_button = %{
      action: %{type: :http_get, to: redirect_url},
      face: %{
        type: :primary,
        label: dgettext("eyra-assignment", "redirect.button")
      }
    }

    socket |> assign(redirect_button: redirect_button)
  end

  defp update_retry_button(socket) do
    retry_button = %{
      action: %{type: :send, event: "retry"},
      face: %{
        type: :plain,
        icon: :back,
        icon_align: :left,
        label: dgettext("eyra-assignment", "retry.button")
      }
    }

    assign(socket, retry_button: retry_button)
  end

  def handle_event("retry", _, socket) do
    {:noreply, socket |> send_event(:parent, "retry")}
  end

  def handle_event("redirect", _, socket) do
    {:noreply, socket |> send_event(:parent, "redirect")}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div class="flex flex-row w-full h-full">
        <div class="flex-grow" />
        <div class="flex flex-col gap-4 sm:gap-8 items-center w-full h-full px-6">
          <div class="flex-grow" />
          <Text.title1 margin=""><%= @title %></Text.title1>
          <div :if={@redirect_url == nil}>
            <Text.body_large align="text-center"><%= @body_default %></Text.body_large>
            <div :if={@redirect_url == nil} class="flex flex-col items-center w-full pt-4">
              <img class="block w-[220px] h-[220px] object-cover" src={~p"/images/illustrations/finished.svg"} id="zero-todos" alt="All tasks done">
            </div>
          </div>
          <div :if={@redirect_url}>
            <Text.body_large align="text-center"><%= @body_redirect %></Text.body_large>
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
