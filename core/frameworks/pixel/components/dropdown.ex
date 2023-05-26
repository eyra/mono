defmodule Frameworks.Pixel.Dropdown do
  use CoreWeb, :html

  attr(:index, :integer, required: true)
  attr(:label, :string, required: true)
  attr(:id, :string)
  attr(:target, :any)

  def option(%{index: index, label: label, target: target} = assigns) do
    assigns =
      assign(assigns, %{
        button: %{
          action: %{type: :send, event: "option_click", item: index, target: target},
          face: %{type: :plain, label: label}
        }
      })

    ~H"""
    <div class="cursor-pointer hover:bg-grey5 px-8 h-10 whitespace-nowrap">
      <Button.dynamic {@button} />
    </div>
    """
  end

  attr(:options, :list, required: true)
  attr(:target, :any)

  def options(assigns) do
    ~H"""
    <div class="bg-white shadow-2xl rounded">
      <div class="max-h-dropdown overflow-y-scroll py-4">
        <div class="flex flex-col items-left">
          <%= for {option, index} <- Enum.with_index(@options) do %>
            <div class="flex-shrink-0">
              <.option index={index} {option} target={@target} />
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
