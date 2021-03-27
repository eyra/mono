defmodule SignInWithApple.Backend do
  def validate_id_token(config, id_token) do
    {:ok, %{claims: claims}} = Assent.Strategy.OIDC.validate_id_token(config, id_token)
    claims
  end

  defdelegate authorize_url(config), to: Assent.Strategy.Apple
end

defmodule SignInWithApple.Helpers do
  def backend_module(config) do
    Keyword.get(config, :apple_backend_module, SignInWithApple.Backend)
  end

  def apply_defaults(config) do
    config
    |> Assent.Strategy.Apple.default_config()
    |> Keyword.merge(config)
  end

  def html_meta(config) do
    config = apply_defaults(config)
    {:ok, %{session_params: session_params}} = backend_module(config).authorize_url(config)

    """
     <meta name="appleid-signin-client-id" content="#{Keyword.get(config, :client_id)}">
     <meta name="appleid-signin-scope" content="name email">
     <meta name="appleid-signin-redirect-uri" content="#{Keyword.get(config, :redirect_uri)}">
     .authorize_url        <meta name="appleid-signin-state" content="#{session_params.state}">
    """
  end

  def html_sign_in_button do
    """
    <div id="appleid-signin" data-color="black" data-border="true" data-type="sign in"></div>
    <script type="text/javascript" src="https://appleid.cdn-apple.com/appleauth/static/jsapi/appleid/1/en_US/appleid.auth.js"></script>
    """
  end
end
