defmodule CoreWeb.Cldr do
  @moduledoc """
  The Cldr backend module (used for i18n).
  """
  use Cldr,
    otp_app: :core,
    locales: ["en", "es", "de", "it", "nl"],
    default: "en",
    gettext: CoreWeb.Gettext,
    providers: [Cldr.Number, Cldr.DateTime]
end
