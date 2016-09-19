defmodule NMDB.Movie do
  defstruct id: nil, full_title: nil, full_year: nil, title: nil, title_year: nil, title_category: nil, years: [], year_open_end: nil, is_episode: nil, episode_name: nil, episode_season: nil, episode_episode: nil, episode_parent_title: nil, suspended: nil

  def run do
    nil
  end

  def movie_line(movie) do
    Enum.join([movie.id, movie.full_title, movie.full_year, movie.title, movie.title_year,
               movie.title_category, movie.year_open_end, movie.is_episode,
               movie.episode_name, movie.episode_season, movie.episode_episode,
               movie.episode_parent_title], "\t") <> "\n"
  end
  
  def movie_writer(file) do
    receive do
      {:movie, movie} ->
        IO.write(file, movie_line(movie))
        movie_writer(file)
      {:done} -> {:done}
      {:error, errno} -> IO.puts("Error-write-movie: #{errno}")
    end
  end

  def year_line(movie_id, year) do
    Enum.join([movie_id, year], "\t") <> "\n"
  end
  
  def write_years(file, movie_id, years) do
    Enum.each(years, fn year ->
      IO.write(file, year_line(movie_id, year))
    end)
  end
  
  def year_writer(file) do
    receive do
      {:movie, movie} ->
        write_years(file, movie.id, movie.years)
        year_writer(file)
      {:done} -> {:done}
      {:error, errno} -> IO.puts("Error-write-year: #{errno}")
    end
  end
  
  def read_line(file, ids, control, moviefilepid, yearfilepid) do
    case IO.read(file, :line) do
      :eof ->
        IO.puts("Done reading")
        send control, {:eof}
      data ->
        movie = parse(ids, data)
        send moviefilepid, {:movie, movie}
        send yearfilepid, {:movie, movie}
        read_line(file, ids, control, moviefilepid, yearfilepid)
    end
  end
  
  def parse_file(ids, filename, moviefilename, yearfilename) do
    IO.puts("Parse-Caller: #{inspect(self())}")
    caller = self()
    moviefilepid =
      case File.open(moviefilename, [:write, :utf8]) do
        {:ok, moviefile} -> 
          spawn_link(fn -> movie_writer(moviefile) end)
       {:error, errno} ->
          IO.puts("Error: #{errno}")
          raise "Unable to open output movie file"
      end
    yearfilepid =
      case File.open(yearfilename, [:write, :utf8]) do
        {:ok, yearfile} -> 
          spawn_link(fn -> year_writer(yearfile) end)
       {:error, errno} ->
          IO.puts("Error: #{errno}")
          raise "Unable to open output movie file"
      end
    case File.open(filename, [:read, :utf8]) do
      {:ok, file} ->
        spawn_link(fn -> read_line(file, ids, caller, moviefilepid, yearfilepid) end)
      {:error, errno} ->
        IO.puts("Error: #{errno}")
        raise "Unable to open output movie file"
    end
    IO.puts("Waiting for EOF...")
    receive do
      {:eof} ->
        IO.puts("Got EOF...")
        send moviefilepid, {:done}
        send yearfilepid, {:done}
    end
  end

  def make_int(string) do
    case Integer.parse(string) do
      :error ->
        IO.puts("Not an integer")
        raise "Not an integer"
      {value, ""} ->
        value
      {_, _} ->
        IO.puts("Not an integer")
        raise "Not a proper integer"
    end
  end

  def get_id({movie, remaining}, ids) do
    ret = {Map.put(movie, :id, NMDB.IDs.find_or_add(ids, movie.full_title)), remaining}
    ret
  end
  
  def extract_full_title({movie, remaining}) do
    parts = remaining |> String.trim |> String.split(~r/\t+/)
    {Map.put(movie, :full_title, hd(parts)), parts |> tl |> hd}
  end

  def extract_full_year({movie, remaining}) do
    {Map.put(movie, :full_year, remaining), nil}
  end

  def extract_suspended({movie, remaining_title}) do
    {suspended, remaining_title} =
      cond do
        # Misspelled variant
      Regex.match?(~r/ \{\{SUSP(EN|NE)D\}\}$/, remaining_title) ->
        {true, remaining_title}
        # Other spellings
      Regex.match?(~r/ \{\{SUSP(EN|NE)DED\}\}$/, remaining_title) ->
        {true, remaining_title}
        # Not suspended
      true ->
        {false, remaining_title}
    end
    {Map.put(movie, :suspended, suspended), remaining_title}
  end
  
  def make_year(movie, start_year, end_year, open) do
    {start_year_int, _} = Integer.parse(start_year)
    {end_year_int, _} = Integer.parse(end_year)
    movie
    |> Map.put(:years, start_year_int..end_year_int)
    |> Map.put(:year_open_end, open)
  end
  
  def extract_year_single({movie, yearstring}) do
    case Regex.run(~r/^(\d\d\d\d)$/, yearstring) do
      [_, year] ->
        {make_year(movie, year, year, false), ""}
      _ ->
        {movie, yearstring}
    end
  end

  def extract_year_closed({movie, yearstring}) do
    case Regex.run(~r/^(\d\d\d\d)-(\d\d\d\d)$/, yearstring) do
      [_, start_year, end_year] ->
        {make_year(movie, start_year, end_year, false), ""}
      _ ->
        {movie, yearstring}
    end
  end
  
  def extract_year_open({movie, yearstring}) do
    case Regex.run(~r/^(\d\d\d\d)-\?\?\?\?$/, yearstring) do
      [_, start_year] ->
        end_year = Integer.to_string(DateTime.utc_now.year)
        {make_year(movie, start_year, end_year, true), ""}
      _ ->
        {movie, yearstring}
    end
  end
  
  def extract_year({movie, _}) do
    {movie, movie.full_year}
    |> extract_year_single
    |> extract_year_closed
    |> extract_year_open
  end
  
  def extract_title_year({movie, remaining}) do
    {title_year, remaining_title} =
      case Regex.run(~r/^(.*) \((....\/[IVX]+)\)$/, remaining) do
        [_, remaining_title, title_year] -> {title_year, remaining_title}
        _ -> case Regex.run(~r/^(.*) \((....)\)$/, remaining) do
               [_, remaining_title, title_year] -> {title_year, remaining_title}
               _ -> {"", remaining}
             end
      end
    {Map.put(movie, :title_year, title_year), remaining_title}
  end

  def extract_title_category({movie, remaining}) do
    {title_category, remaining_title} =
    if String.starts_with?(remaining, "\"") do
      {"TVS", remaining}
    else
      case Regex.run(~r/^(.*) \((TV|V|VG)\)$/, remaining) do
        [_, remaining_title, title_category] -> {title_category, remaining_title}
        _ -> {"", remaining}
      end
    end
    
    {Map.put(movie, :title_category, title_category), remaining_title}
  end
  
  def extract_title({movie, remaining}) do
    {Map.put(movie, :title, remaining), ""}
  end

  def prepare_title({movie, _}) do
    {movie, movie.full_title}
  end

  def extract_episode_parent_title({movie, {title_data, episode_data}}) do
    {Map.put(movie, :episode_parent_title, title_data), {title_data, episode_data}}
  end
  
  def extract_episode_name({movie, {title_data, episode_data}}) do
    {Map.put(movie, :episode_name, String.trim(episode_data)), {title_data, ""}}
  end

  def extract_episode_season({movie, {title_data, episode_data}}) do
    episode_season =
      case Regex.run(~r/\(#(\d+)\.\d+\)$/, episode_data) do
        [_, season] -> season
        nil -> nil
      end
    if episode_season == nil do
      {movie, {title_data, episode_data}}
    else
      {Map.put(movie, :episode_season, make_int(episode_season)), {title_data, episode_data}}
    end
  end

  def extract_episode_episode({movie, {title_data, episode_data}}) do
    {episode_episode, remaining} =
      case Regex.run(~r/^(.*) ?\(#\d+\.(\d+)\)$/, episode_data) do
        [_, remaining, episode] -> {episode, remaining}
        nil -> {nil, episode_data}
      end
    if episode_episode == nil do
      {movie, {title_data, episode_data}}
    else
      {Map.put(movie, :episode_episode, make_int(episode_episode)), {title_data, remaining}}
    end
  end

  def restore_title({movie, {remaining_title, _}}) do
    {movie, remaining_title}
  end
  
  def is_episode_true({movie, remaining}) do
    {Map.put(movie, :is_episode, true), remaining}
  end
  
  def is_episode_false({movie, remaining}) do
    {Map.put(movie, :is_episode, false), remaining}
  end

  def extract_episode({movie, remaining}) do
    case Regex.run(~r/^(.*\)) {(.*)}$/, remaining) do
      [_, title_data, episode_data] ->
        {movie, {title_data, episode_data}}
        |> is_episode_true
        |> extract_episode_parent_title
        |> extract_episode_season
        |> extract_episode_episode
        |> extract_episode_name
        |> restore_title
      _ -> {movie, remaining} |> is_episode_false
    end
  end
  
  def extract_title_parts(data) do
    data
    |> extract_episode
    |> extract_title_category
    |> extract_title_year
    |> extract_title
  end

  def parse(ids, movie_line) do
    {movie, remaining} = {%NMDB.Movie{}, movie_line}
    |> extract_full_title
    |> get_id(ids)
    |> extract_full_year
    |> prepare_title
    |> extract_suspended

    if movie.suspended do
      movie
    else
      {movie, remaining}
      |> extract_title_parts
      |> extract_year
      |> elem(0)
    end
  end
end
