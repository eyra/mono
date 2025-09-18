defmodule Systems.NextAction.View do
  use CoreWeb, :html

  attr(:title, :string, required: true)
  attr(:description, :string, required: true)
  attr(:cta_label, :string, required: true)
  attr(:cta_action, :string, required: true)

  attr(:title_css, :string,
    default: "font-title7 text-title7 md:font-title5 md:text-title5 text-grey1"
  )

  attr(:subtitle_css, :string, default: "text-bodysmall md:text-bodymedium font-body text-grey1")

  def highlight(assigns) do
    ~H"""
    <.normal {assign(assigns, :style, :tertiary)} />
    """
  end

  attr(:title, :string, required: true)
  attr(:description, :string, required: true)
  attr(:cta_label, :string, required: true)
  attr(:cta_action, :string, required: true)
  attr(:style, :string, default: nil)

  attr(:title_css, :string,
    default: "font-title7 text-title7 md:font-title5 md:text-title5 text-grey1"
  )

  attr(:subtitle_css, :string, default: "text-bodysmall md:text-bodymedium font-body text-grey1")

  def normal(%{style: style} = assigns) do
    assigns =
      assign(assigns, %{
        colors: colors(assigns)
      })

    ~H"""
    <Button.action {@cta_action}>
      <div class={"p-4 md:p-6 flex items-center space-x-4 rounded-md #{@colors.bg}"}>
        <div class="flex-grow">
          <div class={"#{@title_css} mb-2"}>
            <%= @title %>
          </div>
          <div class={@subtitle_css}>
            <%= @description %>
          </div>
        </div>
        <div class={"hidden lg:block font-button text-button text-center p-3 rounded-md whitespace-nowrap #{@colors.button}"}>
          <%= @cta_label %>
        </div>
        <div class="inline-block lg:hidden self-start mt-2px md:mt-1">
          <svg width="8" height="13" viewBox="0 0 8 13" class={"fill-current #{@colors.icon}"}>
            <path d="M0.263916 11.34L4.84392 6.75L0.263916 2.16L1.67392 0.75L7.67392 6.75L1.67392 12.75L0.263916 11.34Z" />
          </svg>
        </div>
      </div>
    </Button.action>
    """
  end

  defp colors(%{style: :tertiary}) do
    %{
      bg: "bg-tertiary",
      text: "text-grey1",
      button: "bg-grey1 text-white",
      icon: "text-grey1"
    }
  end

  defp colors(%{style: :warning}) do
    %{
      bg: "bg-warning",
      text: "text-grey1",
      button: "bg-grey1 text-white",
      icon: "text-grey1"
    }
  end

  defp colors(_) do
    %{
      bg: "bg-grey5",
      text: "text-grey1",
      button: "bg-primary text-white",
      icon: "text-primary"
    }
  end
end
