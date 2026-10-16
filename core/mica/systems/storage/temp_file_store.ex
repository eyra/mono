defmodule Systems.Storage.TempFileStore do
  @moduledoc """
  Behaviour for temporary file storage used by data donation.
  """

  @callback store(data :: binary(), file_id :: String.t()) ::
              {:ok, %{id: String.t(), size: non_neg_integer()}} | {:error, term()}

  @callback read(file_id :: String.t()) ::
              {:ok, binary()} | {:error, :not_found | term()}

  @callback delete(file_id :: String.t()) :: :ok | {:error, term()}

  @callback size(file_id :: String.t()) :: non_neg_integer()
end
