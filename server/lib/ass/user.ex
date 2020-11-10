defmodule Ass.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  schema "users" do
    field(:email, :string)
    field(:auth_token, :string)

    timestamps()
  end

  @required_fields ~w(id email)
  @optional_fields ~w(auth_token)

  def changeset(user, params \\ :empty) do
    user
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(:email)
  end
end

