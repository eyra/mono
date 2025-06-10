defmodule Systems.Affiliate.Private do
  def merge(redirect_url, info) when is_binary(redirect_url) and is_binary(info) do
    URI.parse(redirect_url)
    |> merge_query(decode_info(info))
    |> URI.to_string()
  end

  def merge_query(%URI{query: nil} = url, %{} = info) do
    merge_query(%URI{url | query: ""}, info)
  end

  def merge_query(%URI{query: query} = url, %{} = info) do
    %URI{
      url
      | query:
          query
          |> URI.decode_query()
          |> Map.merge(info)
          |> URI.encode_query()
    }
  end

  def decode_info(nil), do: %{}

  def decode_info(info) do
    Jason.decode!(info)
  end
end
