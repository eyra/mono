defmodule CoreWeb.Plug.LiveLocale do
  @moduledoc "A Plug that sets the cldr resolved locale (Cldr.Plug.PutLocale) as session variable."
  import Plug.Conn, only: [put_session: 3]

  def init(options) do
    options
  end

  def call(conn, _opts) do
    locale = Gettext.get_locale()
    put_session(conn, :resolved_locale, locale)
  end
end

defmodule CoreWeb.LiveLocale do
  @moduledoc "A LiveView helper that applies the cldr resolved locale in the current process."

  defmacro __using__(_opts \\ nil) do
    quote do
      @before_compile CoreWeb.LiveLocale
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      defoverridable mount: 3

      def mount(params, %{"resolved_locale" => locale} = session, socket) do
        Gettext.put_locale(CoreWeb.Gettext, locale)
        Gettext.put_locale(Timex.Gettext, locale)
        super(params, session, socket)
      end
    end
  end
end
