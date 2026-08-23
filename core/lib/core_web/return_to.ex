defmodule CoreWeb.ReturnTo do
  @moduledoc """
  Same-origin `return_to` handling shared across auth, onboarding, and
  pool-join flows.

    * `sanitize/1` — accept only same-origin (`/`-prefixed) paths so a
      hostile CTA can't bounce the user to an external site after the
      flow completes. Everything else becomes `nil`.
    * `append/2` — URL-encode and attach a `return_to=<path>` query
      param to a URL, picking `?` or `&` based on whether the target
      already has a query string. `nil` is a no-op.
    * `resolve/2` — pick `return_to` when present, otherwise fall back
      to the caller-provided default. Convenient at "flow finish" call
      sites that would otherwise write `return_to || default`.
  """

  def sanitize("/" <> _rest = path), do: path
  def sanitize(_), do: nil

  def append(path, nil), do: path

  def append(path, return_to) when is_binary(return_to) do
    sep = if String.contains?(path, "?"), do: "&", else: "?"
    "#{path}#{sep}return_to=#{URI.encode_www_form(return_to)}"
  end

  def resolve(return_to, _default) when is_binary(return_to), do: return_to
  def resolve(_, default), do: default
end
