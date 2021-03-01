# In this file, we load configuration and secrets
# from environment variables.

use Mix.Config

google_auth_client_id = System.get_env("GOOGLE_AUTH_CLIENT_ID", "")
google_auth_client_secret = System.get_env("GOOGLE_AUTH_CLIENT_SECRET", "")
