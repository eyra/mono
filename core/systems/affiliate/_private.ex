defmodule Systems.Affiliate.Private do
  def merge(_redirect_url, _user_info, extra_query \\ %{})
  def merge(nil, _user_info, _extra_query), do: {:error, :redirect_url_missing}
  def merge("", _user_info, _extra_query), do: {:error, :redirect_url_missing}
  def merge(redirect_url, %{info: info}, extra_query), do: merge(redirect_url, info, extra_query)

  def merge(redirect_url, info, extra_query)
      when is_binary(redirect_url) and (is_binary(info) or is_nil(info)) do
    url =
      redirect_url
      |> URI.parse()
      |> merge_query(to_map(info))
      |> merge_query(extra_query)
      |> URI.to_string()

    {:ok, url}
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

  def callback(%{affiliate: affiliate}, user_info, event),
    do: callback(affiliate, user_info, event)

  def callback(%{callback_url: nil}, _user_info, _event), do: {:error, :callback_url_missing}
  def callback(%{callback_url: ""}, _user_info, _event), do: {:error, :callback_url_missing}

  def callback(%{callback_url: callback_url}, user_info, event) do
    case merge(callback_url, user_info, event) do
      {:ok, url} -> callback(url)
      error -> error
    end
  end

  def callback(url) when is_binary(url) do
    case :hackney.request(:get, url, [], "", []) do
      {:ok, status, _headers, _client_ref} -> {:ok, status}
      error -> error
    end
  end

  def redirect_url(%{redirect_url: nil}, _user), do: {:error, :redirect_url_missing}
  def redirect_url(%{redirect_url: ""}, _user), do: {:error, :redirect_url_missing}

  def redirect_url(%{redirect_url: redirect_url}, user_info) do
    merge(redirect_url, user_info)
  end
end
