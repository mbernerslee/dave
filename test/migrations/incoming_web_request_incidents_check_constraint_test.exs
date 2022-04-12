defmodule Dave.IncomingWebRequestIncidentsCheckConstraintTest do
  use Dave.DataCase, async: true
  alias Dave.Repo

  describe "incoming_web_request_incidents check constraint" do
    test "historical requests don't need timestamps" do
      now = DateTime.utc_now()

      {1, [%{id: incoming_web_request_id}]} =
        Repo.insert_all(
          "incoming_web_requests",
          [
            %{http_method: "GET", path: "/", inserted_at: now, updated_at: now}
          ],
          returning: [:id]
        )

      assert {1, nil} ==
               Repo.insert_all("incoming_web_request_incidents", [
                 %{incoming_web_request_id: incoming_web_request_id, historical: true}
               ])
    end

    test "non historical requests without timestamps are not allowed" do
      now = DateTime.utc_now()

      {1, [%{id: incoming_web_request_id}]} =
        Repo.insert_all(
          "incoming_web_requests",
          [
            %{http_method: "GET", path: "/", inserted_at: now, updated_at: now}
          ],
          returning: [:id]
        )

      msg = ~r|violates check constraint "historical_dont_need_timestamps"|

      assert_raise Postgrex.Error, msg, fn ->
        Repo.insert_all("incoming_web_request_incidents", [
          %{incoming_web_request_id: incoming_web_request_id, historical: false}
        ])
      end
    end

    test "non historical requests with timestamps are allowed" do
      now = DateTime.utc_now()

      {1, [%{id: incoming_web_request_id}]} =
        Repo.insert_all(
          "incoming_web_requests",
          [
            %{http_method: "GET", path: "/", inserted_at: now, updated_at: now}
          ],
          returning: [:id]
        )

      assert {1, nil} ==
               Repo.insert_all("incoming_web_request_incidents", [
                 %{
                   incoming_web_request_id: incoming_web_request_id,
                   historical: false,
                   inserted_at: now,
                   updated_at: now
                 }
               ])
    end
  end
end
