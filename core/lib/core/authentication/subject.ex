defprotocol Core.Authentication.Subject do
  @moduledoc """
  Subject is a representation of a subject that can be authenticated.
  """

  @doc """
  Returns the name of the subject.
  """
  @spec name(t) :: String.t()
  def name(subject)
end
