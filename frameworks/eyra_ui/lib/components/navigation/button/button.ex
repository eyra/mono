defmodule EyraUI.Navigation.Button do
  use EyraUI.Component

  defviewmodel(
    target: nil,
    method: :get,
    overlay?: false,
    dead?: false
  )

  prop(id, :string, required: true)
  prop(vm, :string, required: true)

  slot(default, required: true)

  alias EyraUI.Navigation.{Get, Dead, Alpine}

  def render(assigns) do
    ~H"""
      <div id={{@id}} phx-hook="NativeWrapper" @click="nativeWrapperHook.toggleSidePanel(); $parent.overlay = {{ overlay?(@vm) }}" >
        <Get :if={{ method(@vm) === :get && !dead?(@vm)}} path={{target(@vm)}}>
          <slot />
        </Get>
        <Dead :if={{dead?(@vm)}} method={{method(@vm) }} path={{target(@vm)}}>
          <slot />
        </Dead>
        <Alpine :if={{ method(@vm) === :alpine}} click_handler={{target(@vm)}}>
          <slot />
        </Alpine>
      </div>
    """
  end
end
