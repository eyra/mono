defmodule Systems.Zircon.Screening.HTML do
  use CoreWeb, :html

  attr(:id, :string, required: true)
  attr(:title, :string, required: true)
  attr(:live_nest_element, :map, required: true)
  attr(:socket, :map, required: true)

  def criterion_cell(%{id: id} = assigns) do
    delete_button = %{
      action: %{type: :send, event: "delete", item: id},
      face: %{type: :icon, icon: :delete_red}
    }

    assigns = assign(assigns, %{delete_button: delete_button})

    ~H"""
      <div class="bg-white rounded-md p-6 w-full">
        <div class="flex flex-col gap-4 w-full">
          <div class="flex flex-row items-center justify-between">
            <Text.title3 margin=""><%= @title %></Text.title3>
            <Button.dynamic {@delete_button} />
          </div>
          <LiveNest.HTML.element {@live_nest_element} socket={@socket} />
        </div>
      </div>
    """
  end
end
