defmodule Systems.Notify.Controller do
  @moduledoc """
  The button of a next action that a notification shows
  (`Notify.Public.open_action/2`) leads here. A click POSTs, with the page's
  CSRF token: the notification is marked seen, which clears its next action,
  then the user goes where the next action's button leads. A GET (the button
  opened in a new tab) only goes there and marks nothing seen. Where that is
  comes from the stored notification, never from the request.
  """
  use MicaWeb,
      {:controller, [formats: [:html], layouts: [html: MicaWeb.Layouts], namespace: MicaWeb]}

  alias Systems.Notify

  def open(%{assigns: %{current_user: user}} = conn, %{"id" => id}),
    do: redirect_to(conn, id, &Notify.Public.open_message(user, &1))

  def show(%{assigns: %{current_user: user}} = conn, %{"id" => id}),
    do: redirect_to(conn, id, &Notify.Public.message_target(user, &1))

  defp redirect_to(conn, id, target) do
    with {message_id, ""} <- Integer.parse(id),
         {:ok, to} <- target.(message_id) do
      redirect(conn, to: to)
    else
      _ -> redirect(conn, to: ~m"/todo")
    end
  end
end
