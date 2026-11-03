defmodule MicaSaas.StartPages do
  @behaviour MicaWeb.StartPageProvider

  def pages(),
    do: %{
      projects: %{id: :projects, path: "/project", domain: "eyra-ui"}
    }

  @impl true
  def values(),
    do: %{
      creator: pages().projects,
      member: pages().projects
    }

  defmacro __using__(_opts) do
    quote do
      use Gettext, backend: MicaWeb.Gettext

      unquote do
        for {id, %{domain: domain}} <- MicaSaas.StartPages.pages() do
          quote do
            dgettext(unquote(domain), unquote("start.page.#{id}"))
          end
        end
      end
    end
  end
end
