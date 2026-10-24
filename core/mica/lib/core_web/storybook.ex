defmodule CoreWeb.Storybook do
  @moduledoc """
  Component storybook for Pixel, served at `/admin/storybook`.

  Stories live in `mica/storybook`; `mix storybook.gen` writes one for every component that lacks
  it. Access goes through `CoreWeb.StorybookGuard`.
  """
  use PhoenixStorybook,
    otp_app: :core,
    title: "Pixel",
    content_path: Path.expand("../../storybook", __DIR__),
    css_path: "/assets/app.css",
    js_path: "/assets/storybook.js",
    sandbox_class: "font-body"
end
