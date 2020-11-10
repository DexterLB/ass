defmodule Ass.Repo.Migrations.RenameSetIdToSpaceId do
  use Ecto.Migration

  def change do
    rename table(:records), :set_key, to: :space_key
    alter table(:records, primary_key: false) do
      modify :space_key, references(:spaces, type: :string, null: :false, column: :key)
    end
  end
end
