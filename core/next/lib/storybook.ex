defmodule Next.Storybook do
  @moduledoc """
  Component storybook for Next-owned components, served at `/admin/storybook-next`.

  Stories live in `next/storybook`; `mix storybook.gen` writes one for every component that lacks
  it. Access goes through `CoreWeb.StorybookGuard`.
  """
  use PhoenixStorybook,
    otp_app: :core,
    title: "Next",
    content_path: Path.expand("../storybook", __DIR__),
    css_path: "/assets/app.css",
    js_path: "/assets/storybook.js",
    sandbox_class: "font-body"
end
