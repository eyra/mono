defmodule Core.ImageCatalog do
  @type image_id :: binary
  @type image_size :: {pos_integer, pos_integer}
  @type url_opts :: [width: pos_integer, height: pos_integer]
  @type image_info :: %{
          id: image_id,
          url: binary,
          srcset: binary,
          blur_hash: nil | binary,
          attribution: nil | Phoenix.HTML.Safe.t()
        }

  @callback search(query :: binary) :: list(image_id)
  @callback search_info(query :: binary, opts :: url_opts) :: list(image_info)

  @doc "Returns the URLs for the given image (if available)"
  @callback info(image :: image_id, opts :: url_opts) :: image_info | nil
end
