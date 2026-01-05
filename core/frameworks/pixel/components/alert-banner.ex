defmodule Frameworks.Pixel.AlertBanner do
  use CoreWeb, :pixel

  @types ~w(success warning error info)a

  @prism_classes %{
    success: "prism-alert-success",
    warning: "prism-alert-warning",
    error: "prism-alert-error",
    info: "prism-alert-info"
  }

  attr(:type, :atom, default: :info, values: @types)
  attr(:message, :string, default: nil)
  attr(:class, :string, default: "")
  slot(:inner_block)

  def alert(assigns) do
    assigns =
      assigns
      |> assign_new(:message, fn -> nil end)
      |> assign(:prism_class, Map.fetch!(@prism_classes, assigns.type))

    ~H"""
    <div class={["prism-alert", @prism_class, @class]}>
      <%= if @message do %>
        <%= @message %>
      <% end %>

      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  # Convenience wrappers: <.success>, <.warning>, etc.
  for type <- @types do
    @doc "Render a #{type} alert"
    def unquote(type)(assigns) do
      assigns = assign(assigns, :type, unquote(type))

      ~H"""
      <.alert {assigns}>
        <%= render_slot(@inner_block) %>
      </.alert>
      """
    end
  end
end
