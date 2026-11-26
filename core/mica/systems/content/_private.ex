defmodule Systems.Content.Private do
  alias Systems.License

  def get_backend do
    Mica.Env.fetch!(:content)
    |> Access.fetch!(:backend)
  end

  def can_user_publish?(%Systems.Account.User{} = user),
    do: License.Public.active?(user, :publish)

  def can_user_publish?(_), do: false
end
