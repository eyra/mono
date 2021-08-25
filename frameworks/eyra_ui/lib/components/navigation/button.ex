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

  alias EyraUI.Navigation.{Get, DeadPost, DeadDelete, DeadGet, Alpine}

  def render(assigns) do
    ~H"""
      <div id={{@id}} phx-hook="NativeWrapper" @click="nativeWrapperHook.toggleSidePanel(); $parent.overlay = {{ overlay?(@vm) }}" >
        <Get :if={{ method(@vm) === :get && !dead?(@vm)}} path={{target(@vm)}}>
          <slot />
        </Get>
        <DeadPost :if={{dead?(@vm) && method(@vm) === :post }} path={{target(@vm)}}>
          <slot />
        </DeadPost>
        <DeadDelete :if={{dead?(@vm) && method(@vm) === :delete }} path={{target(@vm)}}>
          <slot />
        </DeadDelete>
        <DeadGet :if={{dead?(@vm) && method(@vm) === :get }} path={{target(@vm)}}>
          <slot />
        </DeadGet>
        <Alpine :if={{ method(@vm) === :alpine}} click_handler={{target(@vm)}}>
          <slot />
        </Alpine>
      </div>
    """
  end
end
