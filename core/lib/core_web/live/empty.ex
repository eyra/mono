defmodule CoreWeb.Empty do
  @moduledoc """
  A line.
  """
  use Surface.Component

  alias EyraUI.Text.Title1

  prop(title, :string, required: true)
  prop(body, :string, required: true)
  prop(illustration, :string, default: "cards")

  def render(assigns) do
    ~H"""
      <div class="md:hidden grid grid-cols-1 gap-x-10 gap-y-8">
        <Title1>{{ @title }}</Title1>
        <div class="w-full">
          <img class="object-fill w-full" src="/images/illustrations/{{@illustration}}.svg" />
        </div>
        <div class="text-bodymedium sm:text-bodylarge font-body">
          {{ @body }}
        </div>
      </div>

      <div class="hidden md:grid grid-cols-2 gap-x-10 gap-y-8">
        <div>
          <Title1>{{ @title }}</Title1>
          <div class="text-bodymedium sm:text-bodylarge font-body">
            {{ @body }}
          </div>
        </div>
        <div class="w-full">
          <img class="object-fill w-full" src="/images/illustrations/{{@illustration}}.svg" />
        </div>
      </div>
    """
  end
end
