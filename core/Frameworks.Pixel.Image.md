# `Frameworks.Pixel.Image`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/pixel/components/image.ex#L1)

# `blurhash`

An image with fancy features like blur-hash.

## Attributes

* `id` (`:any`) (required)
* `image` (`:any`) (required)
* `style` (`:string`) - Defaults to `"fixed"`.

# `grid`

An image that can be used in an image grid.

## Attributes

* `id` (`:any`) (required)
* `url` (`:any`) (required)
* `srcset` (`:string`) (required)
* `index` (`:string`) (required)
* `target` (`:string`) - Defaults to `""`.
* `selected` (`:boolean`) - Defaults to `false`.

# `preview`

## Attributes

* `image_url` (`:string`)
* `placeholder` (`:string`) (required)
* `shape` (`:string`) - Defaults to `"w-image-preview sm:w-image-preview-sm h-image-preview sm:h-image-preview-sm rounded"`.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
