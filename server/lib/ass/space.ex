defmodule Ass.Space do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:key, :string, []}
  schema "spaces" do
    field(:user_id, :id)

    timestamps()
  end

  @required_fields ~w(user_id)
  @optional_fields ~w()

  def changeset(user, params \\ :empty) do
    user
    |> cast(params, @required_fields, @optional_fields)
    |> foreign_key_constraint(:user_id, message: "Please specify user")
  end
end

