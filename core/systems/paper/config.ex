defmodule Systems.Paper.Config do
  @moduledoc """
  Runtime configuration for the Paper system.
  Provides access to paper import settings.
  """

  @doc """
  Get the batch size for paper imports.
  Defaults to 100 if not configured.
  """
  def import_batch_size do
    Application.get_env(:core, :paper, [])
    |> Keyword.get(:import_batch_size, 100)
  end

  @doc """
  Get the timeout (in milliseconds) for each batch transaction.
  Defaults to 30_000 (30 seconds) if not configured.
  """
  def import_batch_timeout do
    Application.get_env(:core, :paper, [])
    |> Keyword.get(:import_batch_timeout, 30_000)
  end
end
