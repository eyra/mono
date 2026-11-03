defmodule Frameworks.Pixel.RichText do
  @moduledoc """
  Cleans the HTML of the rich-text editor (Trix, `Frameworks.Pixel.Form.wysiwyg_area/1`).

  Every rich-text field goes through `clean/1` when it is saved (its changeset)
  and when it is shown (`Frameworks.Pixel.WysiwygAreaHelpers.render_wysiwyg/1`),
  so text stored before cleaning existed is covered too.

  `clean/1` keeps the tags and attributes the editor produces and removes
  everything else: other tags (their text stays), `script`, `style` and similar
  tags with their content, comments, event and `style` attributes, and links or
  images with an unsafe address. Every link opens in a new tab.
  """

  defmodule Scrubber do
    @moduledoc false
    use HtmlSanitizeEx

    @link_schemes ["http", "https", "mailto", "tel"]

    # Tags whose content is code or data, not text: removed with their content.
    @dropped ~w(script style template iframe object embed noscript textarea select title head svg math)

    def scrub({tag, _attributes, _children}) when tag in @dropped, do: ""

    def scrub({"a", attributes, children}) do
      {"a", scrub_attributes("a", attributes) ++ [{"target", "_blank"}], children}
    end

    # Defining `scrub/1` above replaces the one `use HtmlSanitizeEx` defines.
    strip_comments()

    # The attachment's own description; `content` would be HTML for the editor.
    def scrub_attribute(tag, {"data-trix-attachment", json}) when tag in ["a", "figure"] do
      case Jason.decode(json) do
        {:ok, %{} = attachment} ->
          {"data-trix-attachment", attachment |> Map.delete("content") |> Jason.encode!()}

        _ ->
          nil
      end
    end

    allow_tag_with_uri_attributes("a", ["href"], @link_schemes)

    allow_tag_with_these_attributes("a", [
      "data-trix-attributes",
      "data-trix-content-type"
    ])

    allow_tag_with_uri_attributes("img", ["src"], ["http", "https"])
    allow_tag_with_these_attributes("img", ["alt", "width", "height"])

    allow_tag_with_these_attributes("figure", [
      "data-trix-attributes",
      "data-trix-content-type"
    ])

    # The editor writes div, br, h1, strong, em, del, blockquote, pre, ul, ol,
    # li, figure, img, figcaption and span. The others are plain formatting
    # that text stored earlier may have (`.wysiwyg` styles h2 and h3), kept so
    # it looks the same.
    allow_tags_and_scrub_their_attributes([
      "div",
      "p",
      "br",
      "h1",
      "h2",
      "h3",
      "strong",
      "b",
      "em",
      "i",
      "del",
      "s",
      "u",
      "blockquote",
      "pre",
      "code",
      "ul",
      "ol",
      "li",
      "figcaption",
      "span"
    ])
  end

  @doc "`html` with only the markup of the rich-text editor. `nil` stays `nil`."
  def clean(nil), do: nil
  def clean(html) when is_binary(html), do: Scrubber.sanitize(html)
end
