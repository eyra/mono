defmodule CoreWeb.UI.FunctionComponent do
  use Phoenix.Component

  import Phoenix.LiveView.TagEngine, only: [component: 3]

  attr(:function, :any, required: true)
  attr(:props, :any, required: true)
  slot(:inner_block)

  def function_component(%{props: props} = assigns) do
    props =
      if inner_block = Map.get(assigns, :inner_block) do
        Map.put(props, :inner_block, inner_block)
      else
        props
      end

    assigns = assign(assigns, :props, props)

    ~H"""
    <%= component(
      @function,
      @props,
      {__ENV__.module, __ENV__.function, __ENV__.file, __ENV__.line}
    ) %>
    """
  end
end
