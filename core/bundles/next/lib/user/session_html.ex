defmodule Next.User.SessionHTML do
  use CoreWeb, :html

  alias Systems.Account.UserForm
  import CoreWeb.UI.Footer
  import CoreWeb.UI.Language

  embed_templates("session_html/*")
end
