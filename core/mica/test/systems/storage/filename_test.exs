defmodule Systems.Storage.FilenameTest do
  use ExUnit.Case, async: true

  alias Systems.Storage.Filename

  @real_key "1761568123456-it's (a), b/c: {d} é"

  describe "generate/1" do
    test "keeps the characters real donation keys contain" do
      identifier = [[:assignment, 31], [:source, "whatsapp group chat"], [:key, @real_key]]

      assert "assignment=31_source=whatsapp group chat_key=#{@real_key}.json" ==
               Filename.generate(identifier)
    end

    test "skips parts that are nil or empty" do
      assert "assignment=1_key=k.json" =
               Filename.generate([[:assignment, 1], [:task, nil], [:source, ""], [:key, "k"]])
    end
  end

  describe "valid_identifier?/1" do
    test "accepts the characters real donation keys contain" do
      assert Filename.valid_identifier?([[:key, @real_key]])
    end

    test "accepts integer and nil values" do
      assert Filename.valid_identifier?([[:assignment, 1], [:task, nil]])
    end

    test "rejects a carriage return" do
      refute Filename.valid_identifier?([[:key, "k\rx"]])
    end

    test "rejects a line feed" do
      refute Filename.valid_identifier?([[:key, "k\nx"]])
    end

    test "rejects a NUL byte" do
      refute Filename.valid_identifier?([[:key, "k\0x"]])
    end

    test "rejects a tab" do
      refute Filename.valid_identifier?([[:key, "k\tx"]])
    end

    test "rejects DEL" do
      refute Filename.valid_identifier?([[:key, "k\x7Fx"]])
    end

    test "rejects a control character in any part" do
      refute Filename.valid_identifier?([[:assignment, 1], [:participant, "p\n"], [:key, "k"]])
    end
  end

  describe "url_segment/1" do
    test "keeps the separators of a generated filename" do
      assert "assignment=1_key=k.json" = Filename.url_segment("assignment=1_key=k.json")
    end

    test "decodes back to the filename when it has no slashes" do
      filename = "key=it's (a), c: {d} é.json"
      assert filename == filename |> Filename.url_segment() |> URI.decode()
    end

    test "encodes a space" do
      assert "a%20b" = Filename.url_segment("a b")
    end

    test "replaces a slash" do
      assert "key=.._.._x.json" = Filename.url_segment("key=../../x.json")
    end

    test "replaces a backslash" do
      assert "key=.._x.json" = Filename.url_segment("key=..\\x.json")
    end

    test "encodes a question mark" do
      assert "a%3Fb" = Filename.url_segment("a?b")
    end

    test "encodes a hash" do
      assert "a%23b" = Filename.url_segment("a#b")
    end

    test "encodes a percent sign" do
      assert "a%25b" = Filename.url_segment("a%b")
    end

    test "encodes line breaks" do
      assert "a%0D%0Ab" = Filename.url_segment("a\r\nb")
    end
  end
end
