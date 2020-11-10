defmodule Ass.Email do
  require Logger

  def auth_token(email, token) do
    Logger.info(fn -> ["send auth token to", email, ": ", token] end)

    :ok
  end
end