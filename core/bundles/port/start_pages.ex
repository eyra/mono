defmodule Port.StartPages do
  @behaviour CoreWeb.StartPageProvider

  def pages(),
    do: %{
      console: %{id: :console, target: Port.Console.Page, domain: "eyra-ui"}
    }

  @impl true
  def values(),
    do: %{
      researcher: pages().console,
      student: pages().console,
      coordinator: pages().console,
      member: pages().console
    }

  defmacro __using__(_opts) do
    quote do
      import CoreWeb.Gettext

      unquote do
        for {id, %{domain: domain}} <- Port.StartPages.pages() do
          quote do
            dgettext(unquote(domain), unquote("start.page.#{id}"))
          end
        end
      end
    end
  end
end
