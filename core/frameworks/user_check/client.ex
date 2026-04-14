defmodule Frameworks.UserCheck.Client do
  @moduledoc """
  Behaviour for UserCheck email validation clients.

  Implementations:
  - `Frameworks.UserCheck.HTTPClient` — real API calls (used in releases)
  - `Frameworks.UserCheck.MockClient` — deterministic results (used in dev/test)
  """

  alias Frameworks.UserCheck.ResultModel

  @callback check_email(String.t()) :: {:ok, ResultModel.t()} | {:error, term()}
end
