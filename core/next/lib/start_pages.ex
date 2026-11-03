defmodule Next.StartPages do
  @behaviour MicaWeb.StartPageProvider

  def pages(),
    do: %{
      home: %{id: :home, path: "/", domain: "eyra-ui"},
      projects: %{id: :projects, path: "/project", domain: "eyra-ui"}
    }

  @impl true
  def values(),
    do: %{
      creator: pages().projects,
      member: pages().home
    }

  defmacro __using__(_opts) do
    quote do
      use Gettext, backend: MicaWeb.Gettext

      unquote do
        for {id, %{domain: domain}} <- Next.StartPages.pages() do
          quote do
            dgettext(unquote(domain), unquote("start.page.#{id}"))
          end
        end
      end
    end
  end
end
