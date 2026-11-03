defmodule Frameworks.Pixel.RichText do
  @moduledoc """
  Cleans the HTML of the rich-text editor (Trix, `Frameworks.Pixel.Form.wysiwyg_area/1`).

  Every rich-text field goes through `clean_change/2` when it is saved (its
  changeset) and through `clean/1` when it is shown
  (`Frameworks.Pixel.WysiwygAreaHelpers.render_wysiwyg/1`), so text stored
  before cleaning existed is covered too.

  `clean/1` keeps the tags and attributes the editor produces and removes
  everything else: other tags (their text stays), `script`, `style` and similar
  tags with their content, comments, event and `style` attributes, and links or
  images with an unsafe address. An image whose address is removed is removed
  with its attachment. Every link opens in a new tab.
  """

  import Ecto.Changeset, only: [validate_length: 3, update_change: 3]

  @max_bytes 2_000_000

  # An `&` that doesn't start a character reference. The parser scans ahead
  # from every such `&`, which takes quadratic time on long runs of them.
  @bare_ampersand ~r/&(?![a-z][a-z0-9]{0,31};|#[0-9]{1,7};|#x[0-9a-f]{1,6};)/i

  # A numeric character reference the parser can't decode (it raises above
  # U+10FFFF) or that isn't a character: replaced by U+FFFD, as browsers do.
  @numeric_reference ~r/&#(?:([0-9]{1,7})|x([0-9a-f]{1,6}));/i

  # Whitespace right after a tag, which html_sanitize_ex would replace by its
  # own placeholder characters before parsing. Written as references instead,
  # it comes out as the same whitespace and no placeholder is ever inserted.
  @whitespace_after_tag ~r/>(?:\r?\n| +(?=<)|\t+(?=<))/

  defmodule Address do
    @moduledoc false

    @link_schemes ["http", "https", "mailto", "tel"]
    @image_schemes ["http", "https"]
    @raster_data ~r/\Adata:image\/(?:png|jpeg|gif|webp);base64,[a-z0-9+\/]*={0,2}\z/i

    # What browsers remove from an address before reading its scheme: tabs and
    # line breaks anywhere, control characters and spaces at either end.
    @ignored_anywhere ~r/[\t\n\r]/
    @ignored_at_ends ~r/\A[\x00-\x20]+|[\x00-\x20]+\z/
    @scheme ~r/\A([a-z][a-z0-9+.-]*):/i

    def link?(href) when is_binary(href), do: allowed?(href, @link_schemes)
    def link?(_), do: false

    def image?(src) when is_binary(src),
      do: Regex.match?(@raster_data, src) or allowed?(src, @image_schemes)

    def image?(_), do: false

    # An address without a scheme is relative, and allowed.
    defp allowed?(address, schemes) do
      address =
        address
        |> String.replace(@ignored_anywhere, "")
        |> String.replace(@ignored_at_ends, "")

      case Regex.run(@scheme, address, capture: :all_but_first) do
        [scheme] -> String.downcase(scheme) in schemes
        nil -> true
      end
    end
  end

  defmodule Scrubber do
    @moduledoc false
    use HtmlSanitizeEx

    alias Frameworks.Pixel.RichText.Address

    # Tags whose content is code or data, not text: removed with their content.
    @dropped ~w(script style template iframe object embed noscript textarea select title head svg math)

    def scrub({tag, _attributes, _children}) when tag in @dropped, do: ""

    def scrub({"a", attributes, children}) do
      {"a", scrub_attributes("a", attributes) ++ [{"target", "_blank"}], children}
    end

    def scrub({"img", attributes, children}) do
      attributes = scrub_attributes("img", attributes)

      if List.keymember?(attributes, "src", 0),
        do: {"img", attributes, children},
        else: ""
    end

    def scrub({"figure", attributes, children}) do
      if image_removed?(attributes),
        do: "",
        else: {"figure", scrub_attributes("figure", attributes), children}
    end

    # Text is kept as it is. (The library's own text clauses remove its
    # placeholders, which `clean/1` never lets it insert, and so would remove
    # the same characters typed by a user.)
    def scrub("" <> text), do: text

    # Defining `scrub/1` above replaces the one `use HtmlSanitizeEx` defines.
    strip_comments()

    # The editor reads an attachment and its link from this JSON, so its
    # addresses follow the same rules as `href` and `src`; `content` would be
    # HTML for the editor.
    def scrub_attribute(tag, {name, json})
        when tag in ["a", "figure"] and name in ["data-trix-attachment", "data-trix-attributes"] do
      case Jason.decode(json) do
        {:ok, %{} = data} ->
          {name, data |> Map.delete("content") |> safe_addresses() |> Jason.encode!()}

        _ ->
          nil
      end
    end

    def scrub_attribute("a", {"href", href}) do
      if Address.link?(href), do: {"href", href}
    end

    def scrub_attribute("img", {"src", src}) do
      if Address.image?(src), do: {"src", src}
    end

    def scrub_attribute("figure", {"data-trix-content-type", _} = attribute), do: attribute

    allow_tag_with_these_attributes("a", ["data-trix-content-type"])
    allow_tag_with_these_attributes("img", ["alt", "width", "height"])

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

    defp safe_addresses(data) do
      data
      |> Map.reject(fn {key, value} -> key == "href" and not Address.link?(value) end)
      |> Map.reject(fn {key, value} ->
        key in ["url", "src"] and not Address.image?(value)
      end)
    end

    defp image_removed?(attributes) do
      case List.keyfind(attributes, "data-trix-attachment", 0) do
        {_, json} ->
          case Jason.decode(json) do
            {:ok, %{"url" => url}} -> not Address.image?(url)
            _ -> false
          end

        nil ->
          false
      end
    end
  end

  @doc "The largest rich text, in bytes, a field accepts."
  def max_bytes, do: @max_bytes

  @doc "Whether `html` is over `max_bytes/0`."
  def too_large?(html), do: is_binary(html) and byte_size(html) > @max_bytes

  @doc "`html` with only the markup of the rich-text editor. `nil` stays `nil`."
  def clean(nil), do: nil

  def clean(html) when is_binary(html) do
    @numeric_reference
    |> Regex.replace(html, &character_or_replacement/3)
    |> String.replace(@bare_ampersand, "&amp;")
    |> String.replace(@whitespace_after_tag, &whitespace_as_references/1)
    |> Scrubber.sanitize()
  end

  defp character_or_replacement(reference, decimal, hexadecimal) do
    codepoint =
      if decimal == "",
        do: String.to_integer(hexadecimal, 16),
        else: String.to_integer(decimal)

    if codepoint == 0 or codepoint in 0xD800..0xDFFF or codepoint > 0x10FFFF,
      do: "&#xFFFD;",
      else: reference
  end

  defp whitespace_as_references(">" <> whitespace) do
    ">" <> for(<<char <- whitespace>>, into: "", do: "&##{char};")
  end

  @doc """
  Cleans the change of `field`. Text longer than `max_bytes/0` is an error
  instead, and isn't cleaned.
  """
  def clean_change(changeset, field) do
    changeset = validate_length(changeset, field, max: @max_bytes, count: :bytes)

    if Keyword.has_key?(changeset.errors, field),
      do: changeset,
      else: update_change(changeset, field, &clean/1)
  end
end
