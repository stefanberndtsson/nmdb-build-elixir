defmodule NMDB.IDs do
  defp int_put(ids, name, id) do
    max_id = Map.get(ids, "__max_id")
    ids = if id > max_id do
      Map.put(ids, "__max_id", id)
    else
      ids
    end
    Map.put(ids, name, id)
  end

  defp int_get(ids, name, caller) do
    id = Map.get(ids, name)
    send caller, {:id, id}
    ids
  end

  defp int_find_or_add(ids, name, caller) do
    case Map.get(ids, name) do
      nil ->
        new_id = int_inc_id(ids)
        int_put(ids, name, new_id)
        send caller, {:id, new_id}
      id -> send caller, {:id, id }
    end
    ids
  end
  
  defp int_inc_id(ids) do
    max_id = Map.get(ids, "__max_id")
    Map.put(ids, "__max_id", max_id + 1)
    max_id + 1
  end
  
  defp int_load_file(ids, filename, caller) do
    ids = case File.open(filename, [:read, :utf8]) do
      {:ok, file} -> read_line(ids, file)
      {:error, errno} -> send caller, {:error, errno}
    end
    send caller, {:ok}
    ids
  end

  defp read_line(ids, file) do
    case IO.read(file, :line) do
      :eof -> ids
      data ->
        [name, id] = data |> String.trim |> String.split("\t")
        {id_int, _} = Integer.parse(id)
        int_put(ids, name, id_int) |> read_line(file)
    end
  end

  defp int_inspect(ids) do
    int_inspect(ids, Map.keys(ids))
  end

  defp int_inspect(ids, []) do
    ids
  end
  
  defp int_inspect(ids, [head|tail]) do
    IO.puts "Key: #{head} => #{Map.get(ids, head)}"
    int_inspect(ids, tail)
  end
  
  def handler(ids) do
    receive do
      {:inspect} -> int_inspect(ids) |> handler

      {:load_file, filename, caller} ->
        int_load_file(ids, filename, caller) |> handler

      {:put, name, id} ->
        int_put(ids, name, id) |> handler

      {:get, name, caller} ->
        int_get(ids, name, caller) |> handler

      {:find_or_add, name, caller} ->
        int_find_or_add(ids, name, caller)|> handler

      _ -> raise "Unknown call to handler"
    end
  end

  def run do
    ids = Map.put(%{}, "__max_id", 0)
    spawn_link fn -> handler(ids) end
  end

  def load_file(pid, filename) do
    send pid, {:load_file, filename, self()}
    receive do
      {:ok} -> :ok
      {:error, :enoent} -> raise "File not found"
    end
  end
  
  def find_or_add(pid, name) do
    send pid, {:find_or_add, name, self()}
    receive do
      {:id, id} -> id
    end
  end
  
  def put(pid, name, id) do
    send pid, {:put, name, id}
  end

  def get(pid, name) do
    send pid, {:get, name, self()}
    receive do
      {:id, id} -> id
    end
  end
end
