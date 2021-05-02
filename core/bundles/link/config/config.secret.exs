# In this file, we load configuration and secrets
# from environment variables.

use Mix.Config

google_auth_client_id = System.get_env("GOOGLE_AUTH_CLIENT_ID", "")
google_auth_client_secret = System.get_env("GOOGLE_AUTH_CLIENT_SECRET", "")

config :link, SignInWithApple, private_key: System.get_env("SIGN_IN_WITH_APPLE_PRIVATE_KEY_ID")
