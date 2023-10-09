defmodule Systems.Document.PDFView do
  use CoreWeb, :html

  import Frameworks.Pixel.Line

  attr(:title, :string, required: true)
  attr(:url, :string, required: true)

  def pdf_view(assigns) do
    send(self(), {:complete_task, %{}})

    ~H"""
      <div class="flex flex-col w-full h-full pl-sidepadding pt-sidepadding">
        <Text.title2><%= @title %></Text.title2>
        <.line />
        <div class="flex-grow w-full" >
          <iframe class="w-full h-full" src={"#{@url}#view=FitH&toolbar=0"} />
        </div>
      </div>
    """
  end
end
