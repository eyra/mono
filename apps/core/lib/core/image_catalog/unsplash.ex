defmodule Core.ImageCatalog.Unsplash.Client do
  @type response :: {:ok, any} | {:error, binary}
  @callback get(access_key :: binary, path :: binary, query :: keyword()) :: response
end

defmodule Core.ImageCatalog.Unsplash.HTTP do
  @behaviour Core.ImageCatalog.Unsplash.Client

  def get(access_key, path, query) do
    headers = [
      {"Authorization", "Client-ID #{access_key}"},
      {"Accept-Version", "v1"},
      {"Content-type", "application/json; charset=utf-8"}
    ]

    url =
      URI.merge(
        endpoint(),
        %URI{
          path: path,
          query: URI.encode_query(query)
        }
      )
      |> URI.to_string()

    :hackney.request(:get, url, headers, "", []) |> parse_response()
  end

  defp parse_response({:ok, 200, _, client_ref}) do
    with {:ok, body} <- :hackney.body(client_ref),
         {:ok, json} <- Jason.decode(body) do
      {:ok, json}
    end
  end

  # 200 - OK 	Everything worked as expected
  # 400 - Bad Request 	The request was unacceptable, often due to missing a required parameter
  # 401 - Unauthorized 	Invalid Access Token
  # 403 - Forbidden 	Missing permissions to perform request
  # 404 - Not Found 	The requested resource doesn’t exist
  # 500, 503 	Something went wrong on our end
  #   "errors": ["Username is missing", "Password cannot be blank"]
  #
  defp endpoint, do: Application.get_env(:core, :unsplash_endpoint, "https://api.unsplash.com")
end

defmodule Core.ImageCatalog.Unsplash do
  def search(query) do
    {:ok, json} = client().get(conf().access_key, "/search/photos", query: query, per_page: 2)
    Map.get(json, "results", []) |> Enum.map(&parse_result_item/1)
  end

  def search_info(query, opts) do
    app_name = conf().app_name
    query |> search() |> Enum.map(&info(app_name, &1, opts))
  end

  def info(image_id, opts) do
    info(conf().app_name, image_id, opts)
  end

  defp info(app_name, image_id, opts) do
    %{"raw_url" => raw_url, "username" => username, "name" => name, "blur_hash" => blur_hash} =
      URI.decode_query(image_id)

    safe_username = Phoenix.HTML.Safe.to_iodata(username)
    safe_name = Phoenix.HTML.Safe.to_iodata(name)

    width = Keyword.get(opts, :width, 100)
    height = Keyword.get(opts, :height, 100)

    %{
      id: image_id,
      url: image_url(raw_url, w: width, h: height),
      srcset: 1..3 |> Enum.map(&srcset_item(raw_url, width, height, &1)) |> Enum.join(","),
      blur_hash: blur_hash,
      attribution:
        {:safe,
         ~s(Photo by <a href="https://unsplash.com/@#{safe_username}=#{app_name}&utm_medium=referral">#{
           safe_name
         }</a> on <a href="https://unsplash.com/?utm_source=#{app_name}&utm_medium=referral">Unsplash</a>)}
    }
  end

  defp srcset_item(raw_url, width, height, dpr) do
    "#{image_url(raw_url, w: width, h: height, dpr: dpr)} #{dpr}x"
  end

  defp image_url(raw_url, opts) do
    raw_url
    |> URI.parse()
    |> Map.update!(:query, &image_query(&1, opts))
    |> URI.to_string()
  end

  defp image_query(query_string, opts) when is_nil(query_string) do
    image_query("", opts)
  end

  defp image_query(query_string, opts) do
    query_string
    |> URI.decode_query()
    |> Map.merge(%{auto: :compress})
    |> Map.merge(opts |> Map.new())
    |> URI.encode_query()
  end

  defp parse_result_item(%{
         "urls" => %{"raw" => raw_url},
         "user" => %{"username" => username, "name" => name},
         "blur_hash" => blur_hash
       }) do
    URI.encode_query(raw_url: raw_url, username: username, name: name, blur_hash: blur_hash)
  end

  @spec conf() :: %{access_key: binary(), app_name: binary()}
  defp conf, do: Application.fetch_env!(:core, __MODULE__) |> Enum.into(%{})

  defp client, do: Application.get_env(:core, :unsplash_client, Core.ImageCatalog.Unsplash.HTTP)
end
