defmodule Systems.Localization.Resolvers.LandingPage do
  @moduledoc """
  Determines the locale for the landing page based on authentication and panl participation.
  """

  alias Systems.Localization.Resolvers.BrowserDetection

  @default_locale "en"

  @type opts :: [
          {:logged_in?, boolean()},
          {:panl_participant?, boolean()},
          {:accept_language, String.t() | nil},
          {:put?, boolean()}
        ]

  @spec resolve(map(), opts()) :: String.t()
  def resolve(assigns, opts \\ []) do
    opts =
      opts
      |> Keyword.put_new(:accept_language, accept_language_from(assigns))

    locale = resolve_locale(opts)

    if Keyword.get(opts, :put?, true) do
      CoreWeb.Live.Hook.Locale.put_locale(locale)
    end

    locale
  end

  @spec resolve_locale(opts()) :: String.t()
  def resolve_locale(opts) when is_list(opts) do
    logged_in? = Keyword.get(opts, :logged_in?, false)
    panl_participant? = Keyword.get(opts, :panl_participant?, false)
    accept_language = Keyword.get(opts, :accept_language)

    if logged_in? and not panl_participant? do
      @default_locale
    else
      BrowserDetection.detect_locale(accept_language,
        default_locale: @default_locale
      )
    end
  end

  defp accept_language_from(%{session: session}) when is_map(session) do
    Map.get(session, :accept_language) || Map.get(session, "accept_language")
  end

  defp accept_language_from(_), do: nil
end
