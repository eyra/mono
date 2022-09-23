defmodule Systems.DataDonation.ExecuteSheet do
  use CoreWeb.UI.LiveComponent

  alias Frameworks.Pixel.Text.{Title1, BodyMedium}

  prop(props, :map, required: true)

  data(script, :string)
  data(platform, :string)

  def update(%{id: id, props: %{script: script, platform: platform}}, socket) do
    {:ok, assign(socket, id: id, script: script, platform: platform)}
  end

  def render(assigns) do
    ~F"""
    <ContentArea>
      <MarginY id={:page_top} />
      <SheetArea>
        <Title1>{dgettext("eyra-data-donation", "extract.data.title")}</Title1>
        <code class="hidden">{@script}</code>
        <div id="prompt" />

        <div id="spinner" class="flex flex-row items-center gap-4">
          <BodyMedium>{dgettext("eyra-data-donation", "execute.spinner")}</BodyMedium>
          <div class="w-8 h-8">
            <img src="/images/icons/spinner.svg">
          </div>
        </div>
      </SheetArea>
    </ContentArea>
    """
  end
end
