defmodule EyraUI.Navigation.Button do
  use Surface.Component

  use EyraUI.ViewModel,
    target: nil,
    method: :get,
    overlay?: false,
    dead?: false

  prop(id, :string, required: true)
  prop(vm, :string, required: true)

  slot(default, required: true)

  alias EyraUI.Navigation.{Delete, Get, GetDead, Alpine}

  def render(assigns) do
    ~H"""
      <div id={{@id}} phx-hook="NativeWrapper" @click="nativeWrapperHook.toggleSidePanel(); $parent.overlay = {{ overlay?(@vm) }}" >
        <Get :if={{ method(@vm) === :get && !dead?(@vm)}} path={{target(@vm)}}>
          <slot />
        </Get>
        <GetDead :if={{ method(@vm) === :get && dead?(@vm)}} path={{target(@vm)}}>
          <slot />
        </GetDead>
        <Delete :if={{ method(@vm) === :delete }} path={{target(@vm)}}>
          <slot />
        </Delete>
        <Alpine :if={{ method(@vm) === :alpine}} click_handler={{target(@vm)}}>
          <slot />
        </Alpine>
      </div>
    """
  end
end
