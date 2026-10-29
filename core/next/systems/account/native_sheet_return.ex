defmodule Next.Account.NativeSheetReturn do
  @moduledoc """
  Sends a sign-in sheet of the Next native apps back to the app when its
  sign-in ends on a sign-in page instead of signing in: `failed` when the page
  would show an error (the provider or the registration failed), `cancelled`
  otherwise (for example, the user declined moving their account to the
  provider). Other requests pass through. See `Next.Account.NativeHandoff`.
  """
  @behaviour Plug

  alias Next.Account.NativeHandoff

  @impl true
  def init(opts), do: opts

  @impl true
  def call(%Plug.Conn{method: "GET"} = conn, _opts) do
    if NativeHandoff.pending?(conn) do
      error = if Phoenix.Flash.get(conn.assigns.flash, :error), do: "failed", else: "cancelled"

      conn
      |> Phoenix.Controller.clear_flash()
      |> NativeHandoff.return_error(error)
      |> Plug.Conn.halt()
    else
      conn
    end
  end

  def call(conn, _opts), do: conn
end
