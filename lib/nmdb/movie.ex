defmodule NMDB.Movie do
  defstruct id: nil, full_title: nil, full_year: nil, title: nil, title_year: nil, title_category: nil, years: [], year_open_end: nil, is_episode: nil, episode_name: nil, episode_season: nil, episode_episode: nil, episode_parent_title: nil, suspended: nil

  def run do
    nil
  end

  def extract_full_title({movie, remaining}) do
    parts = remaining |> String.split(~r/\t+/)
    {Map.put(movie, :full_title, hd(parts)), parts |> tl |> hd}
  end

  def extract_full_year({movie, remaining}) do
    {Map.put(movie, :full_year, remaining), nil}
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
      end
    {Map.put(movie, :episode_season, episode_season), {title_data, episode_data}}
  end

  def extract_episode_episode({movie, {title_data, episode_data}}) do
    {episode_episode, remaining} =
      case Regex.run(~r/^(.*) ?\(#\d+\.(\d+)\)$/, episode_data) do
        [_, remaining, episode] -> {episode, remaining}
      end
    {Map.put(movie, :episode_episode, episode_episode), {title_data, remaining}}
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
    |> prepare_title
    |> extract_episode
    |> extract_title_category
    |> extract_title_year
    |> extract_title
  end

  def parse(movie_line) do
    {%NMDB.Movie{}, movie_line}
    |> extract_full_title
    |> extract_full_year
    |> extract_title_parts
    |> extract_year
    |> elem(0)
  end
end
