# In this file, we load configuration and secrets
# from environment variables.

use Mix.Config

google_auth_client_id =
  System.get_env("GOOGLE_AUTH_CLIENT_ID") ||
    raise """
    environment variable GOOGLE_AUTH_CLIENT_ID is missing.
    """

google_auth_client_secret =
  System.get_env("GOOGLE_AUTH_CLIENT_SECRET") ||
    raise """
    environment variable GOOGLE_AUTH_CLIENT_SECRET is missing.
    """

# Registration of oauth providers
config :link, :pow_assent,
  providers: [
    google: [
      client_id: google_auth_client_id,
      client_secret: google_auth_client_secret,
      strategy: Assent.Strategy.Google
    ]
  ]
