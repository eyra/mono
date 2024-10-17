defmodule Frameworks.Pixel.TrixPostProcessor do
  @moduledoc """
  A module for post-processing Trix WYSIWYG output using function chaining.
  Transformations are applied step by step through a pipeline.
  """

  @doc """
  Adds `target="_blank"` to any `<a>` tags that do not already have it.
  It returns the modified HTML content.
  """
  def add_target_blank(html_content) do
    Regex.replace(~r/<a(?![^>]*target=)([^>]*)>/, html_content, "<a\\1 target=\"_blank\">")
  end
end
