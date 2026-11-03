defmodule Systems.Account.SignInHandoff do
  @moduledoc """
  Takes over the end of an identity-provider sign-in, for example to hand it
  to a native app instead of continuing on the site. Systems list their
  handoffs in `c:Mica.System.sign_in_handoffs/0`.

  The identity-provider flows (their callbacks and the move-your-account
  confirm and decline) end through `sign_in/5` and `end_sign_in/4`, which ask
  the handoffs in `Mica.SaaS.sign_in_handoffs/0` order before they do what the
  site does. Other sign-ins don't ask them.
  """

  alias Systems.Account.User

  @type provider :: atom()

  @doc """
  Returns `{:ok, conn}` with the response to send when the handoff takes this
  sign-in through `provider`, or `:skip`. `first_time?` is true for a user who
  registered with this sign-in.
  """
  @callback hand_off(Plug.Conn.t(), provider(), User.t(), first_time? :: boolean()) ::
              {:ok, Plug.Conn.t()} | :skip

  @doc """
  Returns `{:ok, conn}` with the response to send when the handoff takes a
  sign-in through `provider` that ended without signing in: `:failed` (the
  provider or the registration failed) or `:cancelled` (the user stopped it).
  """
  @callback hand_off_unfinished(Plug.Conn.t(), provider(), :failed | :cancelled) ::
              {:ok, Plug.Conn.t()} | :skip

  @doc """
  Ends a sign-in through `provider` that signed `user` in: the first handoff
  that takes it answers, otherwise `log_in_user` does.
  """
  def sign_in(conn, provider, user, first_time?, log_in_user) when is_atom(provider) do
    case ask(& &1.hand_off(conn, provider, user, first_time?)) do
      {:ok, conn} -> conn
      :skip -> log_in_user.(conn, user, first_time?)
    end
  end

  @doc """
  Ends a sign-in through `provider` that did not sign in (`:failed` or
  `:cancelled`): the first handoff that takes it answers, otherwise `otherwise`
  does.
  """
  def end_sign_in(conn, provider, result, otherwise)
      when is_atom(provider) and result in [:failed, :cancelled] do
    case ask(& &1.hand_off_unfinished(conn, provider, result)) do
      {:ok, conn} -> conn
      :skip -> otherwise.(conn)
    end
  end

  defp ask(hand_off) do
    Enum.find_value(Mica.SaaS.sign_in_handoffs(), :skip, fn handoff ->
      case hand_off.(handoff) do
        {:ok, conn} -> {:ok, conn}
        :skip -> nil
      end
    end)
  end
end
