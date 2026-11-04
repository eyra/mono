defmodule Systems.Desktop.FullListPageBuilder do
  def view_model(user, %{live_action: action} = assigns) do
    with section when not is_nil(section) <-
           Enum.find(Mica.SaaS.desktop_sections(), &(&1.id() == action)),
         content when not is_nil(content) <- section.full_view_model(user, assigns) do
      %{
        id: section.id(),
        title: section.title(),
        active_menu_item: :desktop,
        section: section,
        content: content
      }
    else
      _ -> raise Ecto.NoResultsError, queryable: Systems.Account.User
    end
  end
end
