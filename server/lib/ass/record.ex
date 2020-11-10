defmodule Ass.Record do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "records" do
    field(:key, :string, primary_key: true)
    field(:space_key, :string, primary_key: true)
    field(:last_change, :integer)
    field(:last_sync, :integer)
    field(:data, :map)

    timestamps()
  end

  @required_fields ~w(key space_key last_change)
  @optional_fields ~w(data)

  def changeset(user, params \\ :empty) do
    user
    |> cast(params, @required_fields, @optional_fields)
    |> foreign_key_constraint(:space_key, message: "Please specify space")
  end
end

