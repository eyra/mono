defmodule EyraUI.Card.DynamicStudy do
  use EyraUI.Component

  alias EyraUI.Dynamic
  alias EyraUI.Card.{PrimaryStudy, SecondaryStudy}

  prop(conn, :any, required: true)
  prop(path_provider, :any, required: true)
  prop(card, :any, required: true)
  prop(click_event_name, :string)
  prop(click_event_data, :string)

  defp study(%{type: :primary}), do: PrimaryStudy
  defp study(_), do: SecondaryStudy

  def render(assigns) do
    ~H"""
      <Dynamic
        component={{ study(@card) }}
        props={{
          %{
            card: @card,
            conn: @conn,
            path_provider: @path_provider,
            click_event_name: @click_event_name,
            click_event_data: @click_event_data
          }
        }}
      />
    """
  end
end
