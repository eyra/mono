defmodule EyraUI.Navigation.TabbarFooter do
  @moduledoc false
  use Surface.Component

  alias EyraUI.Container.{ContentArea, FormArea}

  alias EyraUI.Button.Action.Click
  alias EyraUI.Button.Face.Forward

  slot(default)

  defp skip_first(list) do
    list |> tl()
  end

  def render(assigns) do
    ~H"""
    <ContentArea top_padding="pt-0">
      <FormArea>
        <Context get={{tabs: tabs}}>
          <div x-show="active_tab == {{ Enum.count(tabs)-1 }}" class="flex flex-row">
            <div class="flex-wrap">
              <slot />
            </div>
          </div>
          <div x-show="active_tab < {{ Enum.count(tabs)-1 }}" class="pt-8">
            <div :for={{ {tab, index} <- Enum.with_index(skip_first(tabs)) }} x-show="active_tab == {{ index }}">
              <Click code="active_tab = active_tab + 1" >
                <Forward label="{{ tab.forward_title }}" />
              </Click>
            </div>
          </div>
        </Context>
      </FormArea>
     </ContentArea>
    """
  end
end
