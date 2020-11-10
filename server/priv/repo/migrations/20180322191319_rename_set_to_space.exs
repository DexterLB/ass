defmodule Ass.Repo.Migrations.RenameSetToSpace do
  use Ecto.Migration

  def change do
    rename table("sets"), to: table("spaces")
  end
end
