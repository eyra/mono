defmodule Link.StartPages do
  @behaviour CoreWeb.StartPageProvider

  def pages(),
    do: %{
      dashboard: %{id: :dashboard, target: Link.Dashboard, domain: "eyra-ui"},
      marketplace: %{id: :marketplace, target: Link.Dashboard, domain: "eyra-ui"}
    }

  @impl true
  def values(),
    do: %{
      researcher: pages().dashboard,
      student: pages().marketplace,
      coordinator: pages().dashboard,
      member: pages().marketplace
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
