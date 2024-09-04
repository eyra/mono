defmodule Core.ImageCatalog.Unsplash.Client do
  @type response :: {:ok, any} | {:error, binary}
  @callback get(access_key :: binary, path :: binary, query :: keyword()) :: response
end

defmodule Core.ImageCatalog.Unsplash.HTTP do
  @behaviour Core.ImageCatalog.Unsplash.Client

  def get(access_key, path, query) when is_list(query) do
    get(access_key, path, URI.encode_query(query))
  end

  def get(access_key, path, query) when is_binary(query) do
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
          query: query
        }
      )
      |> URI.to_string()

    :hackney.request(:get, url, headers, "", []) |> parse_response()
  end

  defp parse_response({:ok, _, _, client_ref}) do
    with {:ok, body} <- :hackney.body(client_ref) do
      Jason.decode(body)
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
  def search(query, page \\ 1, page_size \\ 10) do
    {:ok, json} =
      client().get(conf().access_key, "/search/photos",
        query: query,
        page: page,
        per_page: page_size
      )

    images = json |> Map.get("results", []) |> Enum.map(&parse_result_item/1)
    image_count = json |> Map.get("total")
    page_count = json |> Map.get("total_pages")

    %{
      images: images,
      meta: %{
        image_count: image_count,
        page_count: page_count,
        page: page,
        page_size: page_size,
        begin: page * page_size - page_size + 1,
        end: Enum.min([page * page_size, image_count])
      }
    }
  end

  def random(keyword) when is_atom(keyword) do
    {:ok, item} = client().get(conf().access_key, "/photos/random", "query=#{keyword}")
    parse_result_item(item)
  end

  def random(count) when is_integer(count) do
    {:ok, json} = client().get(conf().access_key, "/photos/random", "count=#{count}")
    Enum.map(json, &parse_result_item/1)
  end

  def search_info(query, page, page_size, opts) do
    app_name = conf().app_name
    search_result = search(query, page, page_size)
    %{search_result | images: search_result.images |> Enum.map(&info(app_name, &1, opts))}
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
      srcset: 1..3 |> Enum.map_join(",", &srcset_item(raw_url, width, height, &1)),
      blur_hash: blur_hash,
      width: width,
      height: height,
      attribution:
        {:safe,
         ~s(Photo by <a href="https://unsplash.com/@#{safe_username}=#{app_name}&utm_medium=referral">#{safe_name}</a> on <a href="https://unsplash.com/?utm_source=#{app_name}&utm_medium=referral">Unsplash</a>)}
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
    |> Map.merge(%{auto: :compress, fit: :crop, crop: "faces,focalpoint"})
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

  defp client do
    Application.get_env(:core, :unsplash_client, Core.ImageCatalog.Unsplash.HTTP)
  end
end
