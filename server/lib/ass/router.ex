defmodule Ass.Router do
  use Plug.Router
  require Logger
  alias Ass.Api

  plug :match
  plug Plug.Parsers, parsers: [:json],
                     pass:  ["application/json"],
                     json_decoder: Poison
  plug :dispatch

  get "/hello" do
    conn |> send_resp(200, "hi\n")
  end

  post "/authenticate" do
    conn |> reply_json(Api.authenticate(conn.body_params))
  end

  post "/login" do
    conn |> reply_json(Api.login(conn.body_params))
  end

  post "/new_space" do
    conn |> reply_json(Api.new_space(conn.body_params))
  end

  post "/push" do
    Logger.debug(fn -> inspect({:push, conn.body_params}) end)
    conn |> reply_json(Api.push(conn.body_params))
  end

  post "/get" do
    Logger.debug(fn -> inspect({:get, conn.body_params}) end)
    conn |> reply_json(Api.get(conn.body_params))
  end

  defp reply_json(conn, data) do
    debug_response(data)

    conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, encode_json(data))
  end

  defp debug_response(resp) do
    Logger.debug(fn -> [" <- ", inspect(resp)] end)
    resp
  end

  defp encode_json(:ok) do
    Poison.encode!("ok")
  end

  defp encode_json({:ok, data}) do
    Poison.encode!(data)
  end

  defp encode_json({:error, err}) do
    Poison.encode!(%{"error" => err})
  end
end