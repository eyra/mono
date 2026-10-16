defmodule Frameworks.Utility.HTTPClient do
  use HTTPoison.Base

  @impl HTTPoison.Base
  def process_request_body(body) when is_map(body) do
    Jason.encode!(body)
  end

  @impl HTTPoison.Base
  def process_request_body(body) when is_binary(body) do
    body
  end
end
