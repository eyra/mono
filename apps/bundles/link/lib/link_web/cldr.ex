defmodule LinkWeb.Cldr do
  @moduledoc """
  The Cldr backend module (used for i18n).
  """
  use Cldr,
    otp_app: :link,
    locales: ["en", "nl"],
    default_locale: "en",
    gettext: LinkWeb.Gettext,
    providers: [Cldr.Number, Cldr.DateTime]
end
