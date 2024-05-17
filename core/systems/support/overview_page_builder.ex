defmodule Systems.Support.OverviewPageBuilder do
  import CoreWeb.Gettext
  alias Systems.Support

  require Systems.Support.TicketStatus

  def view_model(_user, _assigns) do
    %{
      title: dgettext("eyra-admin", "support.title"),
      tabs: create_tabs(),
      show_errors: false,
      active_menu_item: :support
    }
  end

  defp create_tabs() do
    Support.TicketStatus.values()
    |> Enum.map(&{&1, Support.Public.list_tickets(&1)})
    |> Enum.map(fn {status, tickets} ->
      %{
        id: status,
        ready: true,
        title: Support.TicketStatus.translate(status),
        count: Enum.count(tickets),
        type: :fullpage,
        live_component: Support.OverviewTab,
        props: %{
          tickets: tickets
        }
      }
    end)
  end
end
