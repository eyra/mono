defmodule LinkWeb.LiveViewPowHelper do
  alias Link.Users.User
  alias Pow.Store.CredentialsCache

  require Logger

  defmacro __using__(_opts) do
    renewal_config = [renew_session: false, interval: :timer.seconds(5)]
    pow_config = [otp_app: :link, backend: Pow.Store.Backend.EtsCache]

    quote do
      @pow_config unquote(Macro.escape(pow_config)) ++ [module: __MODULE__]
      @renewal_config unquote(Macro.escape(renewal_config)) ++ [module: __MODULE__]

      def get_user(socket, session),
        do: unquote(__MODULE__).get_user(socket, session, @pow_config)

      def assign_current_user(socket, session, user, profile),
        do:
          unquote(__MODULE__).assign_current_user(
            socket,
            session,
            user,
            profile,
            self(),
            @renewal_config
          )

      def handle_info({:renew_pow_session, session}, socket),
        do:
          unquote(__MODULE__).handle_renew_pow_session(
            socket,
            self(),
            session,
            @pow_config,
            @renewal_config
          )
    end
  end

  @doc """
  Retrieves the currently-logged-in user from the Pow credentials cache.
  """
  def get_user(socket, session, pow_config) do
    with {:ok, token} <- verify_token(socket, session, pow_config),
         {user, _metadata} = _pow_credential <- CredentialsCache.get(pow_config, token) do
      user
    else
      _any -> nil
    end
  end

  def assign_current_user(socket, _session, nil = user, _profile, _pid, _renewal_config) do
    socket
    |> Phoenix.LiveView.assign(current_user: user)
  end

  # assigns the current_user to the socket with the key current_user
  def assign_current_user(socket, session, user, profile, pid, renewal_config) do
    maybe_init_session_renewal(
      socket,
      pid,
      session,
      renewal_config |> Keyword.get(:renew_session),
      renewal_config |> Keyword.get(:interval)
    )

    socket
    |> Phoenix.LiveView.assign(current_user: user)
    |> Phoenix.LiveView.assign(current_user_profile: profile)
  end

  # Session Renewal Logic
  # def maybe_init_session_renewal(socket, pid, %{"link_auth" => _signed_token} = session, true, interval) do
  #  if Phoenix.LiveView.connected?(socket) do
  #    Process.send_after(pid, {:renew_pow_session, session}, interval)
  #  end
  # end
  def maybe_init_session_renewal(_, _, _, _, _), do: nil

  def handle_renew_pow_session(socket, pid, session, pow_config, renewal_config) do
    with {:ok, token} <- verify_token(socket, session, pow_config),
         {_user, _metadata} = pow_credential <- CredentialsCache.get(pow_config, token),
         {:ok, _session_token} <- update_session_ttl(pow_config, token, pow_credential) do
      # Successfully updates so queue up another renewal
      Process.send_after(
        pid,
        {:renew_pow_session, session},
        renewal_config |> Keyword.get(:interval)
      )
    else
      _any -> nil
    end

    {:noreply, socket}
  end

  # Verifies the session token
  defp verify_token(socket, %{"link_auth" => signed_token}, pow_config) do
    conn = struct!(Plug.Conn, secret_key_base: socket.endpoint.config(:secret_key_base))
    salt = Atom.to_string(Pow.Plug.Session)
    Pow.Plug.verify_token(conn, salt, signed_token, pow_config)
  end

  defp verify_token(_, _, _), do: nil

  # Updates the TTL on POW credential in the cache
  def update_session_ttl(pow_config, session_token, {%User{} = user, _metadata} = pow_credential) do
    sessions = CredentialsCache.sessions(pow_config, user)

    # Do we have an available session which matches the fingerprint?
    case sessions |> Enum.find(&(&1 == session_token)) do
      nil ->
        Logger.debug("No Matching Session Found")

      # We have an available session. Now lets update it's TTL by passing the previously fetched credential
      _available_session ->
        Logger.debug("Matching Session Found. Updating TTL")
        CredentialsCache.put(pow_config, session_token, pow_credential)
    end
  end
end
