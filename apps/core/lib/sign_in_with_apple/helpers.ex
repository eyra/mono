defmodule SignInWithApple.Backend do
  defdelegate callback(config, id_token), to: Assent.Strategy.Apple

  defdelegate authorize_url(config), to: Assent.Strategy.Apple
end

defmodule SignInWithApple.Helpers do
  import Plug.Conn, only: [put_session: 3, get_session: 2]

  def backend_module(config) do
    Keyword.get(config, :apple_backend_module, SignInWithApple.Backend)
  end

  def apply_defaults(config) do
    config
    |> Assent.Strategy.Apple.default_config()
    |> Keyword.merge(config)
  end

  def html_sign_in_button(conn, config) do
    config = apply_defaults(config)

    session_params = get_session(conn, :sign_in_with_apple)

    """
    <script type="text/javascript" src="https://appleid.cdn-apple.com/appleauth/static/jsapi/appleid/1/en_US/appleid.auth.js"></script>
    <div id="appleid-signin" data-color="black" data-border="true" data-type="sign in"></div>
    <script type="text/javascript">
        AppleID.auth.init({
            clientId: '#{Keyword.get(config, :client_id)}',
            scope: 'name email',
            redirectURI: '#{Keyword.get(config, :redirect_uri)}',
            state: '#{session_params.state}',
        });
    </script>
    """
  end

  def setup_session(conn, config) do
    config = apply_defaults(config)

    {:ok, %{session_params: session_params}} = backend_module(config).authorize_url(config)

    conn |> put_session(:sign_in_with_apple, session_params)
  end
end
