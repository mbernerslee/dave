defmodule Dave.IncomingWebRequestsCheckConstraintTest do
  use Dave.DataCase, async: true
  alias Dave.IncomingWebRequestBuilder

  describe "incoming_web_requests check constraint" do
    test "cannot have duplicate rows with the same http_method and path" do
      path = IncomingWebRequestBuilder.unique_path()

      insert_request = fn ->
        IncomingWebRequestBuilder.build()
        |> IncomingWebRequestBuilder.with_path(path)
        |> IncomingWebRequestBuilder.with_http_method_get()
        |> IncomingWebRequestBuilder.insert()
      end

      insert_request.()

      msg =
        ~r|duplicate key value violates unique constraint \"incoming_web_requests_http_method_path_index\"|

      assert_raise Postgrex.Error, msg, insert_request
    end
  end
end
