defmodule Frameworks.UserCheck.ResultModel do
  @moduledoc """
  Parsed result from the UserCheck email validation API.

  Contains only the fields relevant for email rejection decisions.
  The full API response includes additional fields (domain_authority,
  mx_records list, mx_providers, etc.) that are not stored here.
  """

  @type t :: %__MODULE__{
          disposable: boolean(),
          mx: boolean(),
          blocklisted: boolean(),
          role_account: boolean(),
          public_domain: boolean(),
          alias: boolean(),
          spam: boolean(),
          did_you_mean: String.t() | nil
        }

  defstruct [
    :disposable,
    :mx,
    :blocklisted,
    :role_account,
    :public_domain,
    :alias,
    :spam,
    :did_you_mean
  ]
end
