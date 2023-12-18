defmodule Systems.Assignment.FinishedView do
  use CoreWeb, :live_component_fabric
  use Fabric.LiveComponent

  import CoreWeb.Gettext

  @impl true
  def update(_, socket) do
    body = dgettext("eyra-assignment", "finished_view.body")

    {
      :ok,
      socket |> assign(body: body)
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <div class="flex flex-col gap-8 items-center w-full h-full">
          <div class="wysiwyg text-center">
            <%= raw @body %>
          </div>
          <div class="flex flex-col items-center w-full h-full">
            <div class="flex-grow" />
            <div class="flex-none">
              <img src="/images/illustrations/finished.svg" id="zero-todos" alt="All tasks done">
            </div>
            <div class="flex-grow" />
          </div>
        </div>
      </div>
    """
  end
end
