defmodule Systems.Account.Identity.Email.DefaultRejectionPolicy do
  @moduledoc """
  Default rejection policy for email-first signups.

  Blocks: disposable, invalid MX, blocklisted, role accounts.
  Allows: public domains, aliases, spam (logged but not blocked).
  """

  @behaviour Systems.Account.Identity.Email.RejectionPolicy

  alias Frameworks.UserCheck.ResultModel

  @impl true
  def reject?(%ResultModel{disposable: true}), do: {:error, :disposable}
  def reject?(%ResultModel{raw: %{"mx" => false}}), do: {:error, :invalid_mx}
  def reject?(%ResultModel{blocklisted: true}), do: {:error, :blocklisted}
  def reject?(%ResultModel{role_account: true}), do: {:error, :role_account}
  def reject?(%ResultModel{}), do: :ok
end
