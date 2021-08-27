defmodule CoreWeb.UI.Empty do
  @moduledoc """
  A line.
  """
  use CoreWeb.UI.Component

  alias EyraUI.Text.Title1

  prop(title, :string, required: true)
  prop(body, :string, required: true)
  prop(illustration, :string, default: "cards")

  def render(assigns) do
    ~H"""
      <div class="grid grid-cols-1 md:grid-cols-2 gap-x-10 gap-y-8">
        <div>
          <Title1>{{ @title }}</Title1>
          <div class="text-bodymedium sm:text-bodylarge font-body">
            {{ @body }}
          </div>
        </div>
        <div class="w-full mt-6 md:mt-0">
          <img class="hidden md:block object-fill w-full" src="/images/illustrations/{{@illustration}}.svg" />
          <img class="md:hidden object-fill w-full" src="/images/illustrations/{{@illustration}}_mobile.svg" />
        </div>
      </div>
    """
  end
end
