defmodule PopulateWebRequestTablesTest do
  use Dave.DataCase, async: true
  import Ecto.Query
  alias Dave.{Repo, IncomingWebRequestBuilder}

  unless Code.ensure_loaded?(PopulateWebRequestTables) do
    Code.require_file("./priv/scripts/populate_web_request_tables.exs")
  end

  describe "run/0" do
    test "reads ./log_file and inserts into the database" do
      query =
        from i in "incoming_web_requests",
          inner_join: ii in "incoming_web_request_incidents",
          on: ii.incoming_web_request_id == i.id,
          group_by: i.id,
          order_by: [desc: count(ii.id)],
          select: {i.path, count(ii.id)}

      assert [] == Repo.all(query)

      PopulateWebRequestTables.run()

      assert [{"/", 241} | _] = Repo.all(query)
    end

    test "copes with requests already existing" do
      IncomingWebRequestBuilder.build()
      |> IncomingWebRequestBuilder.with_path("/")
      |> IncomingWebRequestBuilder.with_http_method_get()
      |> IncomingWebRequestBuilder.insert(returning: [:path, :http_method])

      query =
        from i in "incoming_web_requests",
          inner_join: ii in "incoming_web_request_incidents",
          on: ii.incoming_web_request_id == i.id,
          group_by: i.id,
          order_by: [desc: count(ii.id)],
          select: {i.path, count(ii.id)}

      PopulateWebRequestTables.run()

      assert [{"/", 242} | _] = Repo.all(query)
    end
  end
end
