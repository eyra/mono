defmodule Core.Authorization.TestEntity do
  @moduledoc """
  An entity that is only used for test purposes.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "test_entities" do
    field(:title, :string)

    timestamps()
  end

  @doc false
  def changeset(test_entity, attrs) do
    test_entity
    |> cast(attrs, [:title])
    |> validate_required([:title])
  end
end

defmodule Core.TestHelpers do
  @moduledoc """
  Helper functions to make testing convenient.
  """
end

defmodule Core.AuthTestHelpers do
  @moduledoc """
  Helper functions to make testing authorization convenient.
  """
  alias Core.Factories

  def login(user, %{conn: conn}) do
    token = Core.Accounts.generate_user_session_token(user)

    conn =
      conn
      |> Phoenix.ConnTest.init_test_session(%{})
      |> Plug.Conn.put_session(:user_token, token)
      |> Plug.Conn.assign(:current_user, user)

    {:ok, conn: conn, user: user}
  end

  def login_as_member(ctx) do
    password = Factories.valid_user_password()
    {:ok, ctx} = Factories.insert!(:member, %{password: password}) |> login(ctx)
    {:ok, Keyword.put(ctx, :password, password)}
  end

  def login_as_researcher(ctx) do
    Factories.insert!(:researcher) |> login(ctx)
  end

  def extract_user_token_old(fun) do
    {:ok, captured} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token, _] = String.split(captured.body, "[TOKEN]")
    token
  end

  def extract_user_token(fun) do
    {:ok, captured} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token, _] = String.split(captured.text_body, "[TOKEN]")
    token
  end
end
