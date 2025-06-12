defmodule Systems.Affiliate.Private do
  def merge(redirect_url, info_json_string, extra_query \\ %{})
      when is_binary(redirect_url) and is_binary(info_json_string) do
    URI.parse(redirect_url)
    |> merge_query(to_map(info_json_string))
    |> merge_query(extra_query)
    |> URI.to_string()
  end

  def merge_query(%URI{query: nil} = url, %{} = query) do
    merge_query(%URI{url | query: ""}, query)
  end

  def merge_query(%URI{query: old_query} = url, %{} = query) do
    %URI{
      url
      | query:
          old_query
          |> URI.decode_query()
          |> Map.merge(query)
          |> URI.encode_query()
    }
  end

  def to_map(nil), do: %{}

  def to_map(json_string) when is_binary(json_string) do
    Jason.decode!(json_string)
  end

  def callback(url) when is_binary(url) do
    case :hackney.request(:get, url, [], "", []) do
      {:ok, status, _headers, _client_ref} ->
        {:ok, status}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
