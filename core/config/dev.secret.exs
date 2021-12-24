# In this file, we load production configuration and secrets
# from environment variables. You can also hardcode secrets,
# although such is generally not recommended and you have to
# remember to add this file to your .gitignore.
use Mix.Config

config :core, GoogleSignIn,
  client_id: "921548238010-egr9u89cgrg0k4fss3j26pp2suk3gl4k.apps.googleusercontent.com",
  client_secret: "VsQkTNpCB50wWdF1MHcslUYk",
  redirect_uri: "http://localhost:4000/google-sign-in/auth"

config :core, :static_path, "/Users/emiel"

config :core, image_catalog: Core.ImageCatalog.Unsplash

config :core, :admins, ["*@eyra.co"]

# config :core, CoreWeb.Endpoint, debug_errors: false
