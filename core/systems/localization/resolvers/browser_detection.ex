defmodule Systems.Localization.Resolvers.BrowserDetection do
  @moduledoc """
  Implements the browser detection flow based on the `Accept-Language` header.

  Delegates to `Cldr.AcceptLanguage` to stay aligned with configured locales and
  falls back to the default locale when no match is found.
  """

  @default_locale "en"

  @spec detect_locale(String.t() | nil, keyword()) :: String.t()
  def detect_locale(header, opts \\ []) do
    supported =
      normalize_list(opts[:supported_locales] || CoreWeb.Cldr.known_locale_names())

    default =
      case normalize(opts[:default_locale]) do
        nil -> @default_locale
        "" -> @default_locale
        locale -> locale
      end

    if is_binary(header) and header != "" do
      case Cldr.AcceptLanguage.best_match(header, CoreWeb.Cldr) do
        {:ok, %{cldr_locale_name: locale}} ->
          locale = normalize(locale)
          if locale in supported, do: locale, else: default

        _ ->
          default
      end
    else
      default
    end
  end

  defp normalize_list(locales) do
    locales
    |> Enum.map(&normalize/1)
    |> Enum.reject(&is_nil/1)
  end

  defp normalize(nil), do: nil

  defp normalize(locale) when is_atom(locale),
    do: locale |> Atom.to_string() |> normalize()

  defp normalize(locale) when is_binary(locale) do
    locale
    |> String.trim()
    |> String.downcase()
    |> String.replace("_", "-")
  end

  defp normalize(_), do: nil
end
