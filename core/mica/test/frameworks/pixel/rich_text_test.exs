defmodule Frameworks.Pixel.RichTextTest do
  use ExUnit.Case, async: true

  alias Frameworks.Pixel.RichText

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

    test "images with an unsafe address or event attributes" do
      html =
        ~s|<div><img src="javascript:alert(1)"><img src="https://example.org/a.png" onerror="alert(1)"></div>|

      assert RichText.clean(html) == ~s|<div><img /><img src="https://example.org/a.png" /></div>|
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
end
