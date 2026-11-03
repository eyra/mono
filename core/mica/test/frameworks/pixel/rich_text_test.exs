defmodule Frameworks.Pixel.RichTextTest do
  use ExUnit.Case, async: true

  alias Frameworks.Pixel.RichText

  @svg "data:image/svg+xml;base64,PHN2Zz4="

  # Output of the editor (Trix 2.1.19), read from its input after loading each
  # format into it in the browser.
  @trix %{
    text: ~s|<div>Plain text<br>on two lines&nbsp; and two spaces</div>|,
    heading: ~s|<h1>A heading</h1>|,
    bold: ~s|<div>Some <strong>bold</strong> text</div>|,
    italic: ~s|<div>Some <em>italic</em> text</div>|,
    strike: ~s|<div>Some <del>struck</del> text</div>|,
    combined: ~s|<div><strong><em><del>all three</del></em></strong></div>|,
    link: ~s|<div>See <a href="https://example.org/a?b=1&amp;c=2">the docs</a></div>|,
    bold_link: ~s|<div><a href="https://example.org"><strong>bold link</strong></a></div>|,
    mail_link: ~s|<div>Mail <a href="mailto:info@example.org">us</a></div>|,
    quote: ~s|<blockquote>A quote</blockquote>|,
    code: ~s|<pre>if a &lt; b do\n  c\nend</pre>|,
    bullets: ~s|<ul><li>One</li><li>Two</li></ul>|,
    numbers: ~s|<ol><li>One</li><li>Two</li></ol>|,
    nested_lists:
      ~s|<ul><li>One<ul><li>One.one<ol><li>Deep</li></ol></li></ul></li><li>Two</li></ul>|,
    empty_lines: ~s|<div>First<br><br>Third</div><div><br></div>|,
    image:
      ~s|<div><figure data-trix-attachment="{&quot;contentType&quot;:&quot;image&quot;,&quot;height&quot;:20,&quot;url&quot;:&quot;https://example.org/a.png&quot;,&quot;width&quot;:40}" data-trix-content-type="image" class="attachment attachment--preview"><img src="https://example.org/a.png" width="40" height="20"><figcaption class="attachment__caption"></figcaption></figure></div>|
  }

  describe "clean/1 keeps what the editor makes" do
    for {format, html} <- @trix do
      test "#{format}" do
        html = unquote(html)
        assert formatting(RichText.clean(html)) == formatting(html)
      end
    end

    test "writes line breaks as <br /> and non-breaking spaces as characters" do
      assert RichText.clean(@trix.text) ==
               "<div>Plain text<br />on two lines\u00A0 and two spaces</div>"
    end

    test "keeps nested lists as they are" do
      assert RichText.clean(@trix.nested_lists) == @trix.nested_lists
    end

    test "every link opens in a new tab" do
      assert RichText.clean(@trix.link) ==
               ~s|<div>See <a href="https://example.org/a?b=1&amp;c=2" target="_blank">the docs</a></div>|
    end

    for {format, html} <- @trix do
      test "is stable: cleaning cleaned #{format} changes nothing" do
        cleaned = RichText.clean(unquote(html))
        assert RichText.clean(cleaned) == cleaned
      end
    end

    test "nil stays nil" do
      assert RichText.clean(nil) == nil
    end

    test "empty text stays empty" do
      assert RichText.clean("") == ""
    end

    test "plain text without tags is kept, with special characters escaped" do
      assert RichText.clean("Fish & chips") == "Fish &amp; chips"
    end
  end

  describe "clean/1 removes what the editor doesn't make" do
    for tag <- ~w(script style iframe object embed noscript template textarea svg math) do
      test "#{tag}, with its content" do
        tag = unquote(tag)
        html = ~s|<div>Before<#{tag}>alert(1)</#{tag}>after</div>|
        assert RichText.clean(html) == "<div>Beforeafter</div>"
      end
    end

    test "other tags, keeping their text" do
      assert RichText.clean(~s|<div><font color="red">red</font> <marquee>moving</marquee></div>|) ==
               "<div>red moving</div>"
    end

    test "form fields" do
      assert RichText.clean(~s|<form action="/x"><input name="a" value="b">Text</form>|) ==
               "Text"
    end

    test "event, style, class and id attributes" do
      html =
        ~s|<div onclick="alert(1)" style="position:fixed" class="fixed inset-0" id="x">| <>
          ~s|<strong onmouseover="alert(1)">bold</strong></div>|

      assert RichText.clean(html) == "<div><strong>bold</strong></div>"
    end

    for href <- [
          "javascript:alert(1)",
          "JaVaScRiPt:alert(1)",
          " javascript:alert(1)",
          "java&#x09;script:alert(1)",
          "&#106;avascript:alert(1)",
          "vbscript:msgbox(1)",
          "data:text/html;base64,PHNjcmlwdD5hbGVydCgxKTwvc2NyaXB0Pg=="
        ] do
      test "a link to #{href}" do
        html = ~s|<div><a href="#{unquote(href)}">click</a></div>|
        assert RichText.clean(html) == ~s|<div><a target="_blank">click</a></div>|
      end
    end

    test "a link's own target and rel" do
      html = ~s|<div><a href="https://example.org" target="_self" rel="opener">a</a></div>|

      assert RichText.clean(html) ==
               ~s|<div><a href="https://example.org" target="_blank">a</a></div>|
    end

    test "an image's event attributes" do
      html = ~s|<div><img src="https://example.org/a.png" onerror="alert(1)"></div>|
      assert RichText.clean(html) == ~s|<div><img src="https://example.org/a.png" /></div>|
    end

    for src <- [
          "javascript:alert(1)",
          "data:image/svg+xml;base64,PHN2Zz4=",
          "data:text/html;base64,PHNjcmlwdD4=",
          "data:image/png,not-base64"
        ] do
      test "an image from #{src}, with its tag" do
        html = ~s|<div>a<img src="#{unquote(src)}">b</div>|
        assert RichText.clean(html) == "<div>ab</div>"
      end
    end

    test "an image attachment whose address is removed, with its figure" do
      html =
        ~s|<div>a<figure data-trix-attachment="#{attachment(%{contentType: "image/svg+xml", url: @svg})}" | <>
          ~s|data-trix-content-type="image"><img src="#{@svg}"><figcaption></figcaption></figure>b</div>|

      assert RichText.clean(html) == "<div>ab</div>"
    end

    test "an unsafe link in an attachment's description" do
      html =
        ~s|<figure data-trix-attachment="#{attachment(%{url: "https://example.org/a.png", href: "javascript:alert(1)"})}"></figure>|

      assert RichText.clean(html) ==
               ~s|<figure data-trix-attachment="#{attachment(%{url: "https://example.org/a.png"})}"></figure>|
    end

    test "an unsafe link in an attachment's attributes" do
      html =
        ~s|<figure data-trix-attributes="#{attachment(%{caption: "c", href: "javascript:alert(1)"})}"></figure>|

      assert RichText.clean(html) ==
               ~s|<figure data-trix-attributes="#{attachment(%{caption: "c"})}"></figure>|
    end

    test "an unsafe address in a linked attachment's description" do
      html =
        ~s|<a href="https://example.org/f.pdf" data-trix-attachment="#{attachment(%{url: "javascript:alert(1)", href: "https://example.org/f.pdf"})}">f</a>|

      assert RichText.clean(html) ==
               ~s|<a href="https://example.org/f.pdf" data-trix-attachment="#{attachment(%{href: "https://example.org/f.pdf"})}" target="_blank">f</a>|
    end

    test "an attachment's attributes that aren't JSON" do
      assert RichText.clean(~s|<figure data-trix-attributes="nonsense"></figure>|) ==
               "<figure></figure>"
    end

    test "the HTML content of an attachment" do
      json =
        Jason.encode!(%{"contentType" => "x", "content" => "<img src=x onerror=alert(1)>"})

      html = ~s|<figure data-trix-attachment="#{escape(json)}"></figure>|

      assert RichText.clean(html) ==
               ~s|<figure data-trix-attachment="#{escape(~s({"contentType":"x"}))}"></figure>|
    end

    test "an attachment description that isn't one" do
      assert RichText.clean(~s|<figure data-trix-attachment="nonsense"></figure>|) ==
               "<figure></figure>"
    end

    test "comments, such as the block markers of earlier editor versions" do
      assert RichText.clean("<div><!--block-->a<!-- note -->b</div>") == "<div>ab</div>"
    end
  end

  describe "clean/1 keeps pasted images" do
    for type <- ~w(png jpeg gif webp) do
      test "with a data: address of a #{type} image" do
        src = "data:image/#{unquote(type)};base64,iVBORw0KGgo="
        assert RichText.clean(~s|<img src="#{src}">|) == ~s|<img src="#{src}" />|
      end
    end

    test "as an attachment with a data: address, in the page and in the editor" do
      png = "data:image/png;base64,iVBORw0KGgo="
      description = attachment(%{contentType: "image/png", url: png})

      html =
        ~s|<figure data-trix-attachment="#{description}" data-trix-content-type="image">| <>
          ~s|<img src="#{png}"><figcaption></figcaption></figure>|

      assert RichText.clean(html) ==
               ~s|<figure data-trix-attachment="#{description}" data-trix-content-type="image">| <>
                 ~s|<img src="#{png}" /><figcaption></figcaption></figure>|
    end
  end

  describe "clean/1 keeps character references" do
    test "named, numeric and hexadecimal ones, as the characters they stand for" do
      assert RichText.clean("&amp; &nbsp; &#39; &eacute; &#x41;") == "&amp; \u00A0 ' é A"
    end

    test "and writes an & that doesn't start one as &amp;" do
      assert RichText.clean("AT&T a&b") == "AT&amp;T a&amp;b"
    end
  end

  describe "clean/1 leaves no placeholders between tags" do
    test "for a tab before a removed tag" do
      assert RichText.clean("<div>a</div>\t<font>b</font>") == "<div>a</div>\tb"
    end

    test "for spaces before a removed tag" do
      assert RichText.clean("<div>a</div>   <font>b</font>") == "<div>a</div>   b"
    end

    test "for a line break before a removed tag" do
      assert RichText.clean("<div>a</div>\n<font>b</font>") == "<div>a</div>\nb"
    end
  end

  describe "clean/1 reads an address's scheme as browsers do" do
    for {name, href} <- [
          {"split by line breaks", "javascript\n:\nhttps://%0aalert(1)"},
          {"split by encoded line breaks", "javascript&#10;:&#10;https://%0aalert(1)"},
          {"split by named line breaks", "javascript&NewLine;:&NewLine;https://%0aalert(1)"},
          {"split by carriage returns", "javascript\r:\rhttps://%0aalert(1)"},
          {"split by tabs", "javascript\t:\thttps://%0aalert(1)"},
          {"in mixed case, split by line breaks", "JaVaScRiPt\n:\nhttps://%0aalert(1)"},
          {"after control characters", "\u0001 javascript:alert(1)"}
        ] do
      test "removes a javascript: link #{name}" do
        html = ~s|<a href="#{unquote(href)}">a</a>|
        assert RichText.clean(html) == ~s|<a target="_blank">a</a>|
      end
    end

    test "removes an image from a javascript: address split by line breaks" do
      assert RichText.clean(~s|<div>a<img src="javascript\n:\nhttps://x">b</div>|) ==
               "<div>ab</div>"
    end

    test "removes a javascript: link split by line breaks from an attachment's attributes" do
      html =
        ~s|<figure data-trix-attributes="#{attachment(%{caption: "c", href: "javascript\n:\nhttps://%0aalert(1)"})}"></figure>|

      assert RichText.clean(html) ==
               ~s|<figure data-trix-attributes="#{attachment(%{caption: "c"})}"></figure>|
    end

    test "removes a javascript: link split by line breaks from an attachment's description" do
      html =
        ~s|<figure data-trix-attachment="#{attachment(%{url: "https://example.org/a.png", href: "javascript\n:\nhttps://x"})}"></figure>|

      assert RichText.clean(html) ==
               ~s|<figure data-trix-attachment="#{attachment(%{url: "https://example.org/a.png"})}"></figure>|
    end

    for href <- [
          "/path:x?q=a:b",
          "//example.org/a",
          "#top",
          "HTTPS://example.org",
          "https://example.org/a:b"
        ] do
      test "keeps a link to #{href}" do
        href = unquote(href)

        assert RichText.clean(~s|<a href="#{href}">a</a>|) ==
                 ~s|<a href="#{href}" target="_blank">a</a>|
      end
    end
  end

  describe "clean/1 replaces a numeric reference that isn't a character by U+FFFD" do
    for reference <- ~w(&#1114112; &#x110000; &#xFFFFFF; &#xD800; &#0;) do
      test reference do
        assert RichText.clean("<p>a#{unquote(reference)}b</p>") == "<p>a\uFFFDb</p>"
      end
    end

    test "in an address" do
      assert RichText.clean(~s|<a href="https://example.org/&#x110000;">a</a>|) ==
               ~s|<a href="https://example.org/\uFFFD" target="_blank">a</a>|
    end

    test "and keeps one that is" do
      assert RichText.clean("<p>&#x41;&#128512;</p>") == "<p>A😀</p>"
    end
  end

  describe "clean/1 keeps text that looks like the parser's placeholders" do
    # html_sanitize_ex marks whitespace between tags with these characters.
    for text <- ["a ï½¿ b", " ï½¿ b", "a ï¼¿  b", " ï¼¿ b", "xï¾¿y z ï¾¿", " ï¾¿ b"] do
      test inspect(text) do
        html = "<div>#{unquote(text)}</div>"
        assert RichText.clean(html) == html
      end
    end
  end

  # What the text looks like: its elements, attributes and text. Left out:
  # comments, the target every link gets, and the classes on attachments,
  # which no style uses outside the editor. An attachment's description is
  # compared as data.
  defp formatting(html) do
    html
    |> Floki.parse_fragment!()
    |> Floki.traverse_and_update(fn
      {:comment, _} ->
        nil

      {tag, attributes, children} ->
        {tag, Enum.flat_map(attributes, &attribute(tag, &1)), children}

      text ->
        text
    end)
  end

  defp attribute("a", {"target", _}), do: []
  defp attribute(tag, {"class", _}) when tag in ["figure", "figcaption"], do: []

  defp attribute(_tag, {"data-trix-attachment", json}),
    do: [{"data-trix-attachment", Jason.decode!(json)}]

  defp attribute(_tag, attribute), do: [attribute]

  defp escape(text), do: text |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()

  defp attachment(description) do
    description
    |> Map.new(fn {key, value} -> {to_string(key), value} end)
    |> Jason.encode!()
    |> escape()
  end
end
