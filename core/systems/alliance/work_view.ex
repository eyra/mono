defmodule Systems.Alliance.WorkView do
  use CoreWeb, :html

  attr(:url, :string, required: true)

  def work_view(assigns) do
    ~H"""
      <div class="flex flex-col w-full h-full">
        <div class="flex-grow w-full bg-grey6" >
          <iframe class="w-full h-full outline-none" src={"#{@url}#view=FitH&toolbar=0"} />
        </div>
      </div>
    """
  end
end
