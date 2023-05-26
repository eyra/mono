defmodule Systems.Email.EmailHTML do
  use Phoenix.Component

  embed_templates("email/*.html", suffix: "_html")
  embed_templates("email/*.text", suffix: "_text")
end
