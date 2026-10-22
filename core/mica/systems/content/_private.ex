defmodule Systems.Content.Private do
  def get_backend do
    :core
    |> Application.fetch_env!(:content)
    |> Access.fetch!(:backend)
  end

  def can_user_publish?(%{creator: true, verified_at: verified_at}) when not is_nil(verified_at),
    do: true

  def can_user_publish?(_), do: false
end
