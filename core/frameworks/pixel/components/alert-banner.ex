defmodule Frameworks.Pixel.AlertBanner do
  use CoreWeb, :pixel

  @types ~w(success warning error info)a

  @bg_classes %{
    success: "bg-successlight",
    warning: "bg-warninglight",
    error: "bg-errorlight",
    info: "bg-primarylight"
  }

  @text_classes %{
    success: "text-success",
    warning: "text-warning",
    error: "text-error",
    info: "text-primary"
  }

  attr(:type, :atom, default: :info, values: @types)
  attr(:message, :string, default: nil)
  attr(:class, :string, default: "")
  slot(:inner_block)

  def alert(assigns) do
    assigns =
      assigns
      |> assign_new(:message, fn -> nil end)
      |> assign(:bg_class, Map.fetch!(@bg_classes, assigns.type))
      |> assign(:text_class, Map.fetch!(@text_classes, assigns.type))

    ~H"""
    <div
      class={[
        "rounded flex justify-center items-center h-10 px-4 font-label text-label",
        @bg_class,
        @text_class,
        @class
      ]}
    >
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
