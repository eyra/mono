defmodule Link.StartPages do
  @behaviour CoreWeb.StartPageProvider

  def pages(),
    do: %{
      console: %{id: :console, target: Link.Console, domain: "eyra-ui"},
      marketplace: %{id: :marketplace, target: Link.Marketplace, domain: "eyra-ui"}
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
        for {id, %{domain: domain}} <- Link.StartPages.pages() do
          quote do
            dgettext(unquote(domain), unquote("start.page.#{id}"))
          end
        end
      end
    end
  end
end
