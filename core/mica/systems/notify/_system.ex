defmodule Systems.Notify.System do
  use Mica.System

  def routes do
    quote do
      scope "/notify", Systems.Notify do
        pipe_through([:browser, :require_authenticated_user])
        get("/open/:id", Controller, :open)
      end
    end
  end

  def notify_channels, do: %{email: Systems.Notify.Channel.Email, na: Systems.Notify.Channel.NA}
end
