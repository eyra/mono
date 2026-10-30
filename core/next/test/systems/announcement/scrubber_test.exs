defmodule Systems.Announcement.ScrubberTest do
  use ExUnit.Case, async: true

  alias Systems.Announcement.Scrubber

  describe "Trix markup" do
    test "keeps the tags Trix produces" do
      html =
        "<div>Hello <strong>bold</strong> <em>italic</em> <del>struck</del><br />next line</div>" <>
          "<h1>Heading</h1><blockquote>Quote</blockquote><pre>code</pre>" <>
          "<ul><li>bullet</li></ul><ol><li>number</li></ol>"

      assert Scrubber.sanitize(html) == html
    end

    test "removes comments" do
      assert Scrubber.sanitize("<div><!--block-->Text</div>") == "<div>Text</div>"
    end

    test "keeps links that open in a new tab" do
      html =
        ~s'<a href="https://example.org/notes" target="_blank">https</a> ' <>
          ~s'<a href="http://example.org">http</a> ' <>
          ~s'<a href="mailto:support@example.org">mail</a> ' <>
          ~s'<a href="/project">relative</a>'

      assert Scrubber.sanitize(html) == html
    end
  end

  describe "markup outside the allow-list" do
    test "removes script and style tags with their content" do
      assert Scrubber.sanitize("<div>Text<script>alert(1)</script><style>p{}</style></div>") ==
               "<div>Text</div>"
    end

    test "removes script tags nested in other markup" do
      assert Scrubber.sanitize("<svg><script>alert(1)</script></svg>after") == "after"
    end

    test "removes event handlers and other attributes" do
      assert Scrubber.sanitize(
               ~s'<div onmouseover="alert(1)" class="x" style="color: red">Text</div>'
             ) == "<div>Text</div>"

      assert Scrubber.sanitize(~s'<a href="https://example.org" onclick="alert(1)">Link</a>') ==
               ~s'<a href="https://example.org">Link</a>'
    end

    test "removes javascript: and data: links but keeps the link text" do
      for href <- [
            "javascript:alert(1)",
            "JaVaScRiPt:alert(1)",
            " javascript:alert(1)",
            "&#106;avascript:alert(1)",
            "java&#x09;script:alert(1)",
            "data:text/html,<script>alert(1)</script>"
          ] do
        assert Scrubber.sanitize(~s'<a href="#{href}">Link</a>') == "<a>Link</a>"
      end
    end

    test "keeps target only when it opens a new tab" do
      assert Scrubber.sanitize(~s'<a href="https://example.org" target="_top">Link</a>') ==
               ~s'<a href="https://example.org">Link</a>'
    end

    test "removes other tags but keeps their text" do
      assert Scrubber.sanitize(
               ~s'<p><span>Text</span><img src="x" onerror="alert(1)"><iframe src="https://example.org"></iframe></p>'
             ) == "Text"
    end

    test "removes images pasted as Trix attachments" do
      html =
        ~S|<div>See <figure data-trix-attachment="{}" data-trix-content-type="image" class="attachment attachment--preview"><img src="https://example.org/s.png" width="10" height="10"><figcaption class="attachment__caption"></figcaption></figure> it</div>|

      assert Scrubber.sanitize(html) == "<div>See  it</div>"
    end

    test "escapes stray angle brackets in text" do
      assert Scrubber.sanitize("1 < 2 & 3 > 2") == "1 &lt; 2 &amp; 3 &gt; 2"
    end
  end

  describe "text?/1" do
    test "is true when there is text" do
      assert Scrubber.text?("<div>Hi</div>")
      assert Scrubber.text?("<div><a href=\"https://example.org\">link</a></div>")
    end

    test "is false for tags and whitespace only" do
      for html <- [
            "",
            "<div></div>",
            "<div><br /></div>",
            "<div> &nbsp; </div>",
            "<ul><li></li></ul>"
          ] do
        refute Scrubber.text?(html), html
      end
    end
  end
end
