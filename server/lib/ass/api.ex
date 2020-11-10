alias Ass.Email

alias Ass.Repo
alias Ass.User
alias Ass.Session
alias Ass.Space
alias Ass.Record

import Ecto.Changeset, only: [change: 2]
import Ecto.Query
alias Ecto.Multi

require OK
require Logger

defmodule Ass.Api do
  def get(%{"spaces" => spaces, "last_sync" => last_sync}) do
    sync = timestamp_now()

    Repo.all(
      from r in Record,
      where: r.space_key in ^spaces and r.last_sync > ^last_sync
    )
    |> serialise_records(sync)
  end

  def push(%{"records" => records, "last_sync" => last_sync}) do
    case last_sync > timestamp_now() do
      true -> {:error, :future_sync}
      false ->
        Repo.transaction(fn ->
          result = records
          |> Enum.map(fn(rec) -> push_single(rec, last_sync) end)
          |> errmap(&Repo.transaction/1)

          case result do
            :ok -> nil
            {:error, step, err, _} -> Repo.rollback({step, err})
          end
        end)
        |> unwrap_ok_transaction()
    end
  end

  defp push_single(%{"space" => space, "key" => key, "last_change" => last_change, "data" => data}, last_sync) do
    Multi.new
    |> Multi.run(:timestamp_check, fn(_) ->
        case last_change > last_sync + Application.fetch_env!(:ass, :max_future_milliseconds) do
          true ->
            Logger.debug(fn -> ["record ", space, "/", key, " is in the future"] end)
            {:error, :future_timestamp}
          false ->
            {:ok, last_change}
        end
      end)
    |> Multi.run(:record, fn(_) ->
        case Repo.get_by(Record, space_key: space, key: key) do
          nil -> {:ok, %Record{space_key: space, key: key, last_change: 0, last_sync: 0, data: nil}}
          record -> {:ok, record}
        end
      end)
    |> Multi.merge(fn(%{record: record}) ->
        case last_change > record.last_change do
          true ->
            case last_sync <= record.last_sync do
              true ->
                Multi.new
                |> Multi.error(:push_collision_check, :push_collision)
              false ->
                Multi.new
                |> Multi.insert_or_update(:new_record,
                  change(record, last_change: last_change, last_sync: last_sync, data: data))
            end
          false ->
            Logger.debug(fn -> ["record ", space, "/", key, " is older than current"] end)
            Multi.new
        end
      end)
  end

  def new_space(%{"session" => session}) do
    Multi.new
    |> Multi.run(:user, fn(_) ->
        maybe_user = Repo.one(
          from u in User,
          join: s in Session,
          on: s.user_id == u.id,
          where: s.token == ^session
        )
        case maybe_user do
          nil   -> {:error, :not_logged_in}
          user  -> {:ok, user}
        end
      end)
    |> Multi.merge(fn(%{user: user}) ->
        key = new_space_key()
        Multi.new |> Multi.insert(:space, %Space{key: key, user_id: user.id})
      end)
    |> Repo.transaction()
    |> unwrap_new_space_transaction()
  end

  def authenticate(%{"email" => email}) do
    Multi.new
    |> Multi.run(:user, fn(_) ->
        case Repo.get_by(User, email: email) do
          nil   -> {:ok, %User{email: email}}
          user  -> {:ok, user}
        end
      end)
    |> Multi.run(:token, fn(%{user: user}) ->
        token = new_auth_token()
        case Email.auth_token(user.email, token) do
          :ok -> {:ok, token}
          err -> err
        end
      end)
    |> Multi.merge(fn(%{user: user, token: token}) ->
        Multi.new
        |> Multi.insert_or_update(:user_with_token, change(user, auth_token: token))
      end)
    |> Repo.transaction()
    |> unwrap_ok_transaction()
  end

  def login(%{"email" => email, "token" => token}) when not is_nil(token) do
    Multi.new
    |> Multi.run(:user, fn(_) -> {:ok, Repo.get_by(User, email: email)} end)
    |> Multi.run(:user_token, fn(%{user: user}) ->
        case user do
          %User{auth_token: token} -> {:ok, token}
          nil -> {:error, :no_such_user}
          err -> {:error, err}
        end
      end)
    |> Multi.run(:token_check, fn(%{user_token: user_token}) ->
        case user_token == token do
          true -> {:ok, true}
          false -> {:error, :wrong_token}
        end
      end)
    |> Multi.merge(fn(%{user: user}) ->
        Multi.new
        |> Multi.insert(:session, Session.changeset(%Session{}, %{user_id: user.id, token: new_token()}))
        |> Multi.update(:nil_token, change(user, auth_token: nil))
      end)
    |> Repo.transaction()
    |> unwrap_login_transaction()
  end

  defp unwrap_new_space_transaction({:ok, %{space: %Space{key: key}}}) do
    {:ok, %{space: key}}
  end

  defp unwrap_new_space_transaction({:error, step, err, _}) do
    {:error, %{step => err}}
  end

  defp unwrap_new_space_transaction(data) do
    Logger.error(fn -> ["unknown data from new space transaction: ", inspect(data)] end)
    {:error, :unknown}
  end

  defp unwrap_login_transaction({:ok, %{session: %Session{token: token}}}) do
    {:ok, %{session: token}}
  end

  defp unwrap_login_transaction({:error, step, err, _}) do
    {:error, %{step => err}}
  end

  defp unwrap_login_transaction(data) do
    Logger.error(fn -> ["unknown data from login transaction: ", inspect(data)] end)
    {:error, :unknown}
  end

  defp unwrap_ok_transaction({:ok, _}) do
    :ok
  end

  defp unwrap_ok_transaction({:error, step, err, _}) do
    {:error, %{step => err}}
  end

  defp unwrap_ok_transaction({:error, {step, err}}) do
    {:error, %{step => err}}
  end

  defp unwrap_ok_transaction(data) do
    Logger.error(fn -> ["unknown data from authenticate transaction: ", inspect(data)] end)
    {:error, :unknown}
  end

  defp new_auth_token() do
    :crypto.strong_rand_bytes(Application.fetch_env!(:ass, :auth_token_length))
      |> Base.encode16
  end

  defp new_space_key() do
    :crypto.strong_rand_bytes(Application.fetch_env!(:ass, :space_key_length))
      |> Base.url_encode64
  end

  defp new_token() do
    :crypto.strong_rand_bytes(Application.fetch_env!(:ass, :session_token_length))
      |> Base.url_encode64
  end

  defp timestamp_now() do
    :os.system_time(:milli_seconds)
  end

  defp errmap([], _), do: :ok
  defp errmap([h|t], f) do
    case f.(h) do
      {:ok, _} -> errmap(t, f)
      err      -> err
    end
  end

  defp serialise_records(records, sync) do
    blobs = Enum.map(records, &serialise_record/1)
    {:ok, %{
      last_sync:    sync,
      records:      blobs
    }}
  end

  defp serialise_record(%Record{space_key: space, key: key, last_change: last_change, data: data}) do
    %{space: space, key: key, last_change: last_change, data: data}
  end
end