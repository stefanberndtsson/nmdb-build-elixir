defmodule NMDBTest.IDs do
  use ExUnit.Case
  doctest NMDB.IDs

  setup do
    pid = NMDB.IDs.run
    {:ok, [pid: pid]}
  end
  
  test "adding entry to empty map", context do
    id = NMDB.IDs.find_or_add(context[:pid], "Testname")
    assert id == 1
  end

  test "adding entry that exists already", context do
    NMDB.IDs.put(context[:pid], "Testname", 12345)
    id = NMDB.IDs.find_or_add(context[:pid], "Testname")
    assert id == 12345
  end

  test "adding entry that does not exists to a non-empty map", context do
    NMDB.IDs.put(context[:pid], "Testname", 12345)
    id = NMDB.IDs.find_or_add(context[:pid], "Testname 2")
    assert id == 12346
  end

  test "load file with file missing", context do
    assert_raise RuntimeError, "File not found", fn ->
      NMDB.IDs.load_file(context[:pid], "test/no-such-file.tab")
    end
  end
  
  test "load entries from file", context do
    NMDB.IDs.load_file(context[:pid], "test/testfile.tab")
  end
end
