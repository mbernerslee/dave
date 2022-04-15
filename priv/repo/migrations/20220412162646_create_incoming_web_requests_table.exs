defmodule Dave.Repo.Migrations.CreateIncomingWebRequestsTable do
  use Ecto.Migration

  def up do
    create table(:incoming_web_requests) do
      add :http_method, :string, null: false
      add :path, :string, size: 2000, null: false
      timestamps(type: :timestamptz)
    end

    create unique_index(:incoming_web_requests, [:http_method, :path])

    create table(:incoming_web_request_incidents) do
      add :incoming_web_request_id,
          references(:incoming_web_requests, on_delete: :delete_all),
          null: false

      add :historical, :boolean, null: false, default: false
      add :inserted_at, :naive_datetime
      add :updated_at, :naive_datetime
    end

    create constraint("incoming_web_request_incidents", :historical_dont_need_timestamps,
             check:
               "(historical = TRUE and inserted_at IS NULL and updated_at IS NULL) or (historical = FALSE and inserted_at IS NOT NULL and updated_at IS NOT NULL)"
           )
  end

  def down do
    drop table(:incoming_web_request_incidents)
    drop table(:incoming_web_requests)
  end
end
