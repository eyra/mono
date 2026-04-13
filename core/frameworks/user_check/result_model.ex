defmodule Frameworks.UserCheck.ResultModel do
  @moduledoc """
  Parsed result from the UserCheck email validation API.

  Contains the fields relevant for rejection decisions plus the full
  raw response for storage and future analysis.
  """

  @type t :: %__MODULE__{
          disposable: boolean(),
          mx: boolean(),
          blocklisted: boolean(),
          role_account: boolean(),
          public_domain: boolean(),
          alias: boolean(),
          spam: boolean(),
          did_you_mean: String.t() | nil,
          raw: map() | nil
        }

  defstruct [
    :disposable,
    :mx,
    :blocklisted,
    :role_account,
    :public_domain,
    :alias,
    :spam,
    :did_you_mean,
    :raw
  ]
end
