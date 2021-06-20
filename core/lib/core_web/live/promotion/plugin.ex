defmodule CoreWeb.Promotion.Plugin do
  @moduledoc """
  Generic behaviour of a Tool
  """
  alias Core.Promotions.CallToAction
  alias Phoenix.Socket

  @doc """
  Delivers call to action info to embed the tool on the public promotions page
  """
  @callback call_to_action() :: %CallToAction{}

  @doc """
  Handles event from call to action
  """
  @callback handle_event(String.t(), Socket) :: {:ok, Socket} | {:error, String.t()}
end
