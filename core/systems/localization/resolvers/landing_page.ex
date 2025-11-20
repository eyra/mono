defmodule Systems.Localization.Resolvers.LandingPage do
  @moduledoc """
  Determines the locale for the landing page based on authentication and panl participation.
  """

  alias Systems.Localization.Resolvers.BrowserDetection

  @default_locale "en"

  @type opts :: [
          {:logged_in?, boolean()},
          {:panl_participant?, boolean()},
          {:accept_language, String.t() | nil}
        ]

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
end
