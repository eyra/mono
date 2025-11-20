defmodule Systems.Localization.Resolvers.SignupSignin do
  @moduledoc """
  Resolves the locale for signup/signin flows.

  Rules:
  - If the request is for add_to_panl, always use Dutch (`"nl"`).
  - Otherwise use browser detection based on the `Accept-Language` header.
  """

  alias Systems.Localization.Resolvers.BrowserDetection

  @default_locale "en"
  @panl_locale "nl"

  @type opts :: [
          {:add_to_panl?, boolean()},
          {:accept_language, String.t() | nil}
        ]

  @spec resolve(map(), opts()) :: String.t()
  def resolve(assigns, opts \\ []) do
    opts =
      opts
      |> Keyword.put_new(:accept_language, accept_language_from(assigns))
      |> Keyword.put_new(:add_to_panl?, add_to_panl?(assigns))

    locale = resolve_locale(opts)

    CoreWeb.Live.Hook.Locale.put_locale(locale)

    locale
  end

  @spec resolve_locale(opts()) :: String.t()
  def resolve_locale(opts) do
    add_to_panl? = Keyword.get(opts, :add_to_panl?, false)
    accept_language = Keyword.get(opts, :accept_language)

    if add_to_panl? do
      @panl_locale
    else
      BrowserDetection.detect_locale(accept_language,
        default_locale: @default_locale
      )
    end
  end

  defp add_to_panl?(assigns) when is_map(assigns) do
    action =
      Map.get(assigns, :post_signup_action) ||
        Map.get(assigns, "post_signup_action") ||
        Map.get(assigns, :post_signin_action) ||
        Map.get(assigns, "post_signin_action") ||
        Map.get(assigns, :post_action) ||
        Map.get(assigns, "post_action")

    action in [true, :add_to_panl, "add_to_panl"]
  end

  defp add_to_panl?(_), do: false

  defp accept_language_from(%{session: session}) when is_map(session) do
    Map.get(session, :accept_language) || Map.get(session, "accept_language")
  end

  defp accept_language_from(_), do: nil
end
