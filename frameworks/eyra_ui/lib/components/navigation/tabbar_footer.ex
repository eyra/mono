defmodule EyraUI.Navigation.TabbarFooter do
  @moduledoc false
  use Surface.Component

  alias EyraUI.Container.{ContentArea, FormArea}

  alias EyraUI.Button.Action.Click
  alias EyraUI.Button.Face.Forward

  defp skip_first(list) do
    list |> tl()
  end

  def render(assigns) do
    ~H"""
    <ContentArea top_padding="pt-8">
      <FormArea>
        <Context get={{tabs: tabs}}>
          <div :for={{ {tab, index} <- Enum.with_index(skip_first(tabs)) }} x-show="active_tab == {{ index }}">
            <Click code="active_tab = active_tab + 1" >
              <Forward label="{{ tab.forward_title }}" />
            </Click>
          </div>
        </Context>
      </FormArea>
     </ContentArea>
    """
  end
end
