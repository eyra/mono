defmodule Next.Announcement.ScrubberTest do
  use ExUnit.Case, async: true

  alias Next.Announcement.Scrubber

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

    test "escapes stray angle brackets in text" do
      assert Scrubber.sanitize("1 < 2 & 3 > 2") == "1 &lt; 2 &amp; 3 &gt; 2"
    end
  end
end
