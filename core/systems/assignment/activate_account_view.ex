defmodule Systems.Assignment.ActivateAccountView do
  use CoreWeb, :embedded_live_view
  use Gettext, backend: CoreWeb.Gettext

  alias Frameworks.Pixel.Button
  alias Frameworks.Pixel.Flash
  alias Frameworks.Pixel.Text
  alias CoreWeb.UI.Area
  alias CoreWeb.UI.Margin

  alias Systems.Account

  def dependencies(), do: [:user_id]

  def get_model(:not_mounted_at_router, _session, %{assigns: %{user_id: user_id}}) do
    Account.Public.get_user!(user_id)
  end

  @impl true
  def mount(:not_mounted_at_router, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_event("resend", _params, %{assigns: %{model: user}} = socket) do
    case Account.Public.deliver_user_confirmation_instructions(
           user,
           &(CoreWeb.Endpoint.url() <> "/user/confirm/#{&1}")
         ) do
      {:ok, _} ->
        {:noreply,
         socket
         |> Flash.push_info(dgettext("eyra-assignment", "activate_account.resend.success"))}

      {:error, :already_confirmed} ->
        {:noreply, socket |> publish_event(:email_confirmed)}
    end
  end

  @impl true
  def handle_event("check_confirmed", _params, %{assigns: %{model: %{id: user_id}}} = socket) do
    fresh_user = Account.Public.get_user!(user_id)

    if Account.Public.confirmed?(fresh_user) do
      {:noreply, socket |> publish_event(:email_confirmed)}
    else
      {:noreply,
       socket
       |> Flash.push_error(dgettext("eyra-assignment", "activate_account.not_yet_confirmed"))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Margin.y id={:page_top} />
      <Area.sheet>
        <div class="flex flex-col items-center">
          <Text.title2>{@vm.title}</Text.title2>
          <.spacing value="S" />
          <Text.body align="text-center">{Phoenix.HTML.raw(@vm.body)}</Text.body>
        </div>
        <.spacing value="L" />
        <div class="flex flex-row gap-4 justify-center">
          <Button.dynamic {@vm.check_button} />
          <Button.dynamic {@vm.resend_button} />
        </div>
      </Area.sheet>
    </div>
    """
  end
end
