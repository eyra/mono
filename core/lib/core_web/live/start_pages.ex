defmodule CoreWeb.StartPages do
  @behaviour CoreWeb.StartPageProvider

  def pages(),
    do: %{
      dashboard: %{id: :dashboard, target: CoreWeb.Dashboard, domain: "eyra-ui"}
    }

  @impl true
  def values(),
    do: %{
      researcher: pages().dashboard,
      student: pages().dashboard,
      coordinator: pages().dashboard,
      member: pages().dashboard
    }

  defmacro __using__(_opts) do
    quote do
      import CoreWeb.Gettext

      unquote do
        for {id, %{domain: domain}} <- CoreWeb.StartPages.pages() do
          quote do
            dgettext(unquote(domain), unquote("start.page.#{id}"))
          end
        end
      end
    end
  end
end
