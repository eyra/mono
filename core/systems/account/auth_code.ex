defmodule Systems.Account.AuthCodeModel do
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
      where: t.attempts < @max_attempts,
      order_by: [desc: t.inserted_at],
      limit: 1
    )
  end

  defp generate_code do
    :rand.uniform(round(:math.pow(10, @code_length)))
    |> Integer.to_string()
    |> String.pad_leading(@code_length, "0")
  end

  defp hash_code(code), do: :crypto.hash(@hash_algorithm, code)
end
