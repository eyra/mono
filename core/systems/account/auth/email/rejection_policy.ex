defmodule Systems.Account.Auth.Email.RejectionPolicy do
  @moduledoc """
  Behaviour for email rejection policies.

  Given a UserCheck result, decide whether the email should be rejected.
  Callers of `Systems.Account.Auth.Email.register/2` can pass a custom policy module
  to override the default rejection rules.
  """

  alias Frameworks.UserCheck.ResultModel

  @callback reject?(ResultModel.t()) :: :ok | {:error, atom()}
end
