defmodule Frameworks.Pixel.Catalogue do
  @moduledoc """
  Catalogue implementation.
  """

  use Surface.Catalogue

  @impl true
  def config() do
    [
      head_css: """
      <link phx-track-static rel="stylesheet" href="/css/app.css"/>
      """,
      head_js: """
      <script defer type="module" src="/js/app.js"></script>
      """,
      playground: [
        body: [
          style: "padding: 1.5rem; height: 100%;",
          class: "has-background-light"
        ]
      ]
    ]
  end
end
