defmodule CoreWeb.LiveLocale do
  @moduledoc "A LiveView helper that changes the locale of the current process"

  def put_locale(locale) when is_atom(locale), do: put_locale(Atom.to_string(locale))

  def put_locale(locale) do
    CoreWeb.Cldr.put_locale(locale)
    Gettext.put_locale(locale)
    Gettext.put_locale(CoreWeb.Gettext, locale)
    Gettext.put_locale(Timex.Gettext, locale)
  end

  def get_locale() do
    Gettext.get_locale()
  end

  defmacro __using__(_opts \\ nil) do
    quote do
      @before_compile CoreWeb.LiveLocale
      import CoreWeb.LiveLocale
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      defoverridable mount: 3

      @impl true
      def mount(params, session, socket) do
        super(params, session, socket |> assign(locale: CoreWeb.LiveLocale.get_locale()))
      end
    end
  end
end
