defmodule Dave.RequestPersisterTest do
  use Dave.DataCase, async: true
  import ExUnit.CaptureLog

  alias Dave.{
    Constants,
    RequestPersister,
    IncomingWebRequestBuilder
  }

  alias Dave.Support.DBQueries

  describe "save_in_db/2" do
    test "given a new path & method, stores them in the db & returns them in an ok tuple" do
      http_method = Constants.http_method_get()
      path = IncomingWebRequestBuilder.unique_path()

      assert DBQueries.all_paths_and_methods_with_counts() == []

      assert {:ok, %{http_method: http_method, path: path}} ==
               RequestPersister.save_in_db(path, http_method)

      assert DBQueries.all_paths_and_methods_with_counts() == [{path, http_method, 1}]
    end

    test "given an already seen path and method, stores them in the db as a new incident" do
      %{http_method: http_method, path: path} =
        IncomingWebRequestBuilder.build()
        |> IncomingWebRequestBuilder.insert(returning: [:path, :http_method])

      assert DBQueries.all_paths_and_methods_with_counts() == [{path, http_method, 1}]
      assert {:ok, _} = RequestPersister.save_in_db(path, http_method)
      assert DBQueries.all_paths_and_methods_with_counts() == [{path, http_method, 2}]
    end

    test "logs an error if the path is over 2000 characters & doesn't store anything in the DB" do
      http_method = Constants.http_method_get()
      path = String.duplicate("a", 2001)

      logging =
        capture_log(fn ->
          assert :error == RequestPersister.save_in_db(path, http_method)
        end)

      assert Regex.match?(
               ~r|^.*\[error\] A web request came in for a path longer that 2000 characters\n|,
               logging
             )

      assert DBQueries.all_paths_and_methods_with_counts() == []
    end
  end
end
