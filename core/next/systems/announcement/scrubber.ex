defmodule Systems.Announcement.Scrubber do
  @moduledoc """
  Cleans announcement bodies: keeps only the tags and attributes the Pixel
  `wysiwyg_area` (Trix) produces with its toolbar. Other tags are removed and
  their text is kept, except for `script` and `style`, which are removed with
  their content. Comments are removed. Images, which Trix takes as attachments
  when they are pasted, are removed too.

  Links keep `href` for `http`, `https` and `mailto` URLs and relative ones, and
  `target="_blank"` from `Frameworks.Pixel.TrixPostProcessor.add_target_blank/1`.
  """
  use HtmlSanitizeEx

  allow_tag_with_uri_attributes("a", ["href"], ["http", "https", "mailto"])
  allow_tag_with_this_attribute_values("a", "target", ["_blank"])

  allow_tag_with_these_attributes("blockquote", [])
  allow_tag_with_these_attributes("br", [])
  allow_tag_with_these_attributes("del", [])
  allow_tag_with_these_attributes("div", [])
  allow_tag_with_these_attributes("em", [])
  allow_tag_with_these_attributes("h1", [])
  allow_tag_with_these_attributes("li", [])
  allow_tag_with_these_attributes("ol", [])
  allow_tag_with_these_attributes("pre", [])
  allow_tag_with_these_attributes("strong", [])
  allow_tag_with_these_attributes("ul", [])

  # Defining scrub/1 here replaces the comment clause `use HtmlSanitizeEx` adds.
  def scrub({:comment, _text}), do: ""
  def scrub({tag, _attributes, _children}) when tag in ["script", "style"], do: ""

  @doc "Whether cleaned HTML has text a reader sees, not only tags and whitespace."
  def text?(html) do
    html
    |> HtmlSanitizeEx.strip_tags()
    |> String.replace("&nbsp;", " ")
    |> String.trim() != ""
  end
end
