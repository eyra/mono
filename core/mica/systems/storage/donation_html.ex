defmodule Systems.Storage.DonationHTML do
  @moduledoc "Shows one donation as the blocks of `Storage.DonationView`."
  use CoreWeb, :html

  attr(:path, :string, required: true)
  attr(:blocks, :any, required: true)

  def donation(assigns) do
    ~H"""
    <div class="p-8 overflow-x-auto" data-testid="donation-view">
      <div class="text-title5 font-title5 mb-6 break-all"><%= @path %></div>
      <.block block={@blocks} />
    </div>
    """
  end

  attr(:block, :any, required: true)

  def block(%{block: {:table, columns, rows}} = assigns) do
    assigns = assign(assigns, columns: columns, rows: rows)

    ~H"""
    <table class="text-bodysmall font-body border-collapse mb-6" data-testid="donation-table">
      <tr>
        <%= for column <- @columns do %>
          <th class="border border-grey4 px-2 py-1 text-left font-label"><%= column %></th>
        <% end %>
      </tr>
      <%= for row <- @rows do %>
        <tr>
          <%= for value <- row do %>
            <td class="border border-grey4 px-2 py-1"><%= format(value) %></td>
          <% end %>
        </tr>
      <% end %>
    </table>
    """
  end

  def block(%{block: {:tree, scalars, children}} = assigns) do
    assigns = assign(assigns, scalars: scalars, children: children)

    ~H"""
    <div>
      <%= if @scalars do %>
        <.block block={@scalars} />
      <% end %>
      <%= for {key, child} <- @children do %>
        <div class="ml-4">
          <div class="text-label font-label mb-2"><%= key %></div>
          <.block block={child} />
        </div>
      <% end %>
    </div>
    """
  end

  def block(%{block: {:list, children}} = assigns) do
    assigns = assign(assigns, children: children)

    ~H"""
    <div>
      <%= for child <- @children do %>
        <.block block={child} />
      <% end %>
    </div>
    """
  end

  def block(%{block: {:value, value}} = assigns) do
    assigns = assign(assigns, value: value)

    ~H"""
    <div class="text-bodysmall font-body mb-2"><%= format(@value) %></div>
    """
  end

  defp format(nil), do: ""
  defp format(value) when is_boolean(value), do: to_string(value)
  defp format(values) when is_list(values), do: Enum.map_join(values, ", ", &format/1)
  defp format(value), do: value
end
