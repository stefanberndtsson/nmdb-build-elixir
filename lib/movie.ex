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
  
  def parse(movie_line) do
    {%NMDB.Movie{}, movie_line}
    |> extract_full_title
    |> extract_full_year
    |> elem(0)
  end
end
