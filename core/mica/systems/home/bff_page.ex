defmodule Systems.Home.BFFPage do
  @moduledoc "The BFF's home page: the user's To-dos, one card each, in the To-do page's order."
  @behaviour Systems.BFF.Page

  alias Systems.BFF.Blocks.Card
  alias Systems.NextAction

  @impl true
  def blocks(user) do
    for %{title: title, description: body, cta_label: cta, cta_action: action} <-
          NextAction.Public.list_next_actions(user) do
      %Card{title: title, body: body, cta: cta, to: to(action)}
    end
  end

  defp to(%{type: :redirect, to: to}), do: to
  defp to(_action), do: nil
end
