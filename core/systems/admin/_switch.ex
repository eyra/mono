defmodule Systems.Admin.Switch do
  use Frameworks.Signal.Handler

  alias Systems.Admin

  @impl true
  def intercept({:bank_account, _}, %{from_pid: from_pid}) do
    update_page(Admin.ConfigPage, %{id: :singleton}, from_pid)
    :ok
  end

  @impl true
  def intercept({:pool, _}, %{pool: %{director: :citizen}, from_pid: from_pid}) do
    update_page(Admin.ConfigPage, %{id: :singleton}, from_pid)
    :ok
  end

  defp update_page(page, %{id: id} = model, from_pid) do
    dispatch!({:page, page}, %{id: id, model: model, from_pid: from_pid})
  end
end
