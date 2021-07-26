defmodule EyraUI.Navigation.Button do
  use Surface.Component

  prop(id, :string, required: true)
  prop(action, :string, required: true)
  prop(method, :atom, default: :get)
  prop(dead, :boolean, default: true)
  prop(overlay, :string, default: "$parent.overlay = false")

  slot(default, required: true)

  alias EyraUI.Navigation.{Delete, Get, GetDead, Alpine}

  defp is_dead?(%{dead: true}), do: true
  defp is_dead?(_), do: false

  def render(assigns) do
    ~H"""
      <div id={{@id}} phx-hook="NativeWrapper" @click="nativeWrapperHook.toggleSidePanel(); {{ @overlay }}" >
        <Get :if={{ @method === :get && !is_dead?(@action)}} path={{@action.path}}>
          <slot />
        </Get>
        <GetDead :if={{ @method === :get && is_dead?(@action)}} path={{@action.path}}>
          <slot />
        </GetDead>
        <Delete :if={{ @method === :delete }} path={{@action.path}}>
          <slot />
        </Delete>
        <Alpine :if={{ @method === :alpine}} click_handler={{@action.click_handler}}>
          <slot />
        </Alpine>
      </div>
    """
  end
end
