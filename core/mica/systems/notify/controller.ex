defmodule Systems.Notify.Controller do
  @moduledoc """
  The button of a next action that a notification shows
  (`Notify.Public.open_action/2`) leads here: the notification is marked seen,
  which clears its next action, then the user goes where the next action's
  button leads. Where that is comes from the stored notification, never from
  the request.
  """
  use MicaWeb,
      {:controller, [formats: [:html], layouts: [html: MicaWeb.Layouts], namespace: MicaWeb]}

  alias Systems.Notify

  def open(%{assigns: %{current_user: user}} = conn, %{"id" => id}) do
    with {message_id, ""} <- Integer.parse(id),
         {:ok, to} <- Notify.Public.open_message(user, message_id) do
      redirect(conn, to: to)
    else
      _ -> redirect(conn, to: ~m"/todo")
    end
  end
end
