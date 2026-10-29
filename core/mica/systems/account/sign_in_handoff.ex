defmodule Systems.Account.SignInHandoff do
  @moduledoc """
  Takes over the response of a sign-in, for example to hand it to a native app
  instead of continuing on the site. Systems list their handoffs in
  `c:Core.System.sign_in_handoffs/0`; `Systems.Account.UserAuth.log_in_user/4`
  asks them in order before it starts a session and redirects.
  """

  alias Systems.Account.User

  @doc """
  Returns `{:ok, conn}` with the response to send when the handoff takes this
  sign-in, or `:skip` to leave it to the next handoff or the usual redirect.
  `first_time?` is true for a user who registered with this sign-in.
  """
  @callback hand_off(conn :: Plug.Conn.t(), user :: User.t(), first_time? :: boolean()) ::
              {:ok, Plug.Conn.t()} | :skip
end
