defmodule Core.ImageCatalog do
  @type image_id :: binary
  @type image_size :: {pos_integer, pos_integer}
  @type url_opts :: [width: pos_integer, height: pos_integer]
  @type image_info :: %{
          id: image_id,
          url: binary,
          width: pos_integer(),
          height: pos_integer(),
          srcset: binary,
          blur_hash: nil | binary,
          attribution: nil | Phoenix.HTML.Safe.t()
        }

  @type meta_info :: %{
          page: pos_integer,
          page_size: pos_integer,
          page_count: non_neg_integer,
          image_count: non_neg_integer,
          begin: pos_integer,
          end: pos_integer
        }

  @type search_result :: %{
          images: list(image_id),
          meta: meta_info
        }

  @type search_info_result :: %{
          images: list(image_info),
          meta: meta_info
        }

  @callback search(query :: binary, page :: pos_integer, page_size :: pos_integer) ::
              search_result
  @callback search_info(
              query :: binary,
              page :: pos_integer,
              page_size :: pos_integer,
              opts :: url_opts
            ) :: search_info_result

  @doc "Returns the URLs for the given image (if available)"
  @callback info(image :: image_id, opts :: url_opts) :: image_info | nil
end
