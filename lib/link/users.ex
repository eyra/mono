defmodule Link.Users do
  @moduledoc """
  The Users context.
  """
  use Pow.Ecto.Context,
    repo: Link.Repo,
    user: Link.Users.User

  alias Link.Repo
  alias Link.Users.{Profile, User}

  def create(params) do
    pow_create(params)
  end

  def create!(params) do
    {:ok, user} = create(params)
    user
  end

  def get_profile(%User{id: user_id}) do
    get_profile(user_id)
  end

  def get_profile(user_id) do
    Repo.get_by(Profile, user_id: user_id) || create_profile!(user_id)
  end

  def get_display_label(%User{} = user) do
    user_profile = get_profile(user)
    cond do
      user_profile.fullname != nil -> user_profile.fullname
      user_profile.displayname != nil -> user_profile.displayname
      true -> user.email
    end
  end

  def get_display_label(user_id) do
    get_by(id: user_id)
    |> get_display_label()
  end

  def update_profile(%Profile{} = profile, attrs) do
    profile
    |> Profile.changeset(attrs)
    |> Repo.update()
  end

  def change_profile(%Profile{} = profile, attrs \\ %{}) do
    Profile.changeset(profile, attrs)
  end

  defp create_profile!(user_id) do
    %Profile{user_id: user_id}
    |> Repo.insert!()
  end

end
