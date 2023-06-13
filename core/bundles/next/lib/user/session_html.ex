defmodule Next.User.SessionHTML do
  use CoreWeb, :html

  alias CoreWeb.User.Form
  import CoreWeb.UI.Footer
  import CoreWeb.UI.Language

  embed_templates("session_html/*")
end
