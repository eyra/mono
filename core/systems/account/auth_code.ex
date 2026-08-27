defmodule Systems.Account.AuthCodeModel do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Query

  @hash_algorithm :sha256
  @validity_in_minutes 10
  @max_attempts 5
  @code_length 6

  schema "auth_codes" do
    field(:code_hash, :binary)
    field(:email, :string)
    field(:attempts, :integer, default: 0)
    belongs_to(:user, Systems.Account.User)

    timestamps(updated_at: false)
  end

  def build(email, user_id) do
    code = generate_code()

    auth_code = %__MODULE__{
      code_hash: hash_code(code),
      email: email,
      attempts: 0,
      user_id: user_id
    }

    {code, auth_code}
  end

  def verify(%__MODULE__{attempts: attempts}, _code) when attempts >= @max_attempts do
    {:error, :max_attempts}
  end

  def verify(%__MODULE__{code_hash: code_hash}, code) do
    if :crypto.hash(@hash_algorithm, code) == code_hash do
      :ok
    else
      {:error, :invalid}
    end
  end

  def active_query(email) do
    from(t in __MODULE__,
      where: t.email == ^email,
      where: t.inserted_at > ago(@validity_in_minutes, "minute"),
      order_by: [desc: t.id],
      limit: 1
    )
  end

  def expired_query do
    from(t in __MODULE__,
      where: t.inserted_at <= ago(@validity_in_minutes, "minute")
    )
  end

  defp generate_code do
    min = Integer.pow(10, @code_length - 1)
    max = Integer.pow(10, @code_length) - 1

    random_int = 4 |> :crypto.strong_rand_bytes() |> :binary.decode_unsigned()

    Integer.to_string(min + rem(random_int, max - min + 1))
  end

  defp hash_code(code), do: :crypto.hash(@hash_algorithm, code)
end
