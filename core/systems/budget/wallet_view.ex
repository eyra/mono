defmodule Systems.Budget.WalletView do
  use CoreWeb, :html

  alias Frameworks.Pixel.Text
  import CoreWeb.UI.ProgressBar

  attr(:items, :list, required: true)

  def list(assigns) do
    ~H"""
    <div class="flex flex-col gap-10">
      <%= for item <- @items do %>
        <.item {item} />
      <% end %>
    </div>
    """
  end

  attr(:title, :string, required: true)
  attr(:subtitle, :string, default: nil)
  attr(:target_amount, :integer, default: 0)
  attr(:earned_amount, :integer, default: 0)
  attr(:earned_label, :string, default: "")
  attr(:pending_amount, :integer, default: 0)
  attr(:pending_label, :string, default: "")
  attr(:togo_amount, :integer, default: 0)
  attr(:togo_label, :string, default: "")

  attr(:title_css, :string,
    default: "font-title7 text-title7 md:font-title5z md:text-title5 text-grey1"
  )

  attr(:subtitle_css, :string,
    default: "text-bodysmall md:text-bodymedium font-body text-grey2 whitespace-pre-wrap"
  )

  def item(assigns) do
    ~H"""
    <div class="font-sans bg-grey5 flex items-stretch space-x-4 rounded-md">
      <div class="flex flex-row w-full">
        <div class="flex-grow p-4 lg:p-6">
          <div class="w-full h-full">
            <div class="flex flex-col sm:flex-row  w-full h-full gap-x-4 gap-y-8 justify-center">
              <div class="flex-wrap md:w-48 lg:w-56">
                <div class="flex flex-col gap-2 h-full justify-center">
                  <div class={@title_css}><%= @title %></div>
                  <%= if @subtitle do %>
                    <div class={@subtitle_css}><%= @subtitle %></div>
                  <% end %>
                </div>
              </div>
              <div class="flex-grow">
                <.progress_bar
                  bg_color="bg-grey3"
                  size={max(@target_amount, @earned_amount + @pending_amount)}
                  bars={[
                    %{color: :warning, size: @earned_amount + @pending_amount},
                    %{color: :success, size: @earned_amount}
                  ]}
                />

                <div class="flex flex-row flex-wrap gap-y-4 gap-x-8 mt-6">
                  <%= if @earned_amount > 0 do %>
                    <div class="flex flex-row items-center gap-3">
                      <div class="flex-shrink-0 w-6 h-6 -mt-2px rounded-full bg-success" />
                      <Text.label><%= @earned_label %></Text.label>
                    </div>
                  <% end %>

                  <%= if @pending_amount > 0 do %>
                    <div class="flex flex-row items-center gap-3">
                      <div class="flex-shrink-0 w-6 h-6 -mt-2px rounded-full bg-warning" />
                      <Text.label><%= @pending_label %></Text.label>
                    </div>
                  <% end %>

                  <%= if @togo_amount > 0 do %>
                    <div class="flex flex-row items-center gap-3">
                      <div class="flex-shrink-0 w-6 h-6 -mt-2px rounded-full bg-grey3" />
                      <Text.label><%= @togo_label %></Text.label>
                    </div>
                  <% end %>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
