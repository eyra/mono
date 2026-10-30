defmodule MicaWeb.Cldr do
  @moduledoc """
  The Cldr backend module (used for i18n).
  """
  use Cldr,
    otp_app: :mica,
    locales: ["en", "es", "de", "it", "nl", "ro", "lt"],
    default: "en",
    gettext: MicaWeb.Gettext,
    providers: [Cldr.Number, Cldr.DateTime]
end
