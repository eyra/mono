defmodule Systems.Fund.BalanceView do
  use CoreWeb, :html

  import CoreWeb.UI.ProgressBar
  alias Frameworks.Pixel.Text

  attr(:progress, :map, required: true)
  attr(:available, :string, required: true)
  attr(:reserved, :string, required: true)
  attr(:spend, :string, required: true)

  def balance_view(assigns) do
    ~H"""
    <div class="bg-grey6 rounded p-12">
      <.progress_bar {@progress} />
      <div class="flex flex-row flex-wrap gap-y-4 gap-x-12 mt-12">
        <div>
          <div class="flex flex-row items-center gap-3">
            <div class="flex-shrink-0 w-6 h-6 rounded-full bg-success" />
            <Text.label><%= @available %> <%= dgettext("eyra-fund", "fund.available.label") %></Text.label>
          </div>
        </div>
        <div>
          <div class="flex flex-row items-center gap-3">
            <div class="flex-shrink-0 w-6 h-6 rounded-full bg-warning" />
            <Text.label><%= @reserved %> <%= dgettext("eyra-fund", "fund.reserved.label") %></Text.label>
          </div>
        </div>
        <div>
          <div class="flex flex-row items-center gap-3">
            <div class="flex-shrink-0 w-6 h-6 rounded-full bg-grey4" />
            <Text.label><%= @spend %> <%= dgettext("eyra-fund", "fund.spend.label") %></Text.label>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
