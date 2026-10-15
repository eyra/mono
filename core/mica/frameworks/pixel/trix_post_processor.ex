defmodule Frameworks.Pixel.TrixPostProcessor do
  @moduledoc """
  A module for post-processing Trix WYSIWYG output using function chaining.
  Transformations are applied step by step through a pipeline.
  """

  @doc """
  Adds `target="_blank"` to any `<a>` tags that do not already have it.
  It returns the modified HTML content.

  ## Regex Breakdown:
  - `<a`: Matches the opening part of an <a> tag.
  - `(?![^>]*target=)`: Negative lookahead to ensure the <a> tag does not already have a `target` attribute.
  - `[^>]*`: Ensures that no characters up to the closing `>` of the tag contain `target=`.
  - `([^>]*)`: Captures the remaining attributes inside the <a> tag.
  """
  def add_target_blank(html_content) do
    Regex.replace(~r/<a(?![^>]*target=)([^>]*)>/, html_content, "<a\\1 target=\"_blank\">")
  end
end
