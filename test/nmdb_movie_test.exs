defmodule NMDBTest.Movie do
  use ExUnit.Case
  doctest NMDB.Movie

  setup do
    pid = NMDB.Movie.run
    movie1 = "Total Recall (1990)\t\t\t\t\t1990"
    movie2 = "Total Recall (2012/I) (TV)\t\t\t\t\t2012"
    movie3 = "Total Recall (2012/II) (VG)\t\t\t\t\t2012"
    series_main = "\"Fawlty Towers\" (1975)\t\t\t\t\t1975-1979"
    series_episode = "\"Fawlty Towers\" (1975) {Basil the Rat (#2.6)}\t\t1979"
    {:ok, [pid: pid, movie1: movie1, movie2: movie2, movie3: movie3, series_main: series_main, series_episode: series_episode]}
  end
  
  test "extract_full_title", context do
    %NMDB.Movie{full_title: full_title} = NMDB.Movie.parse(context[:movie1])
    assert "Total Recall (1990)" = full_title
    %NMDB.Movie{full_title: full_title} = NMDB.Movie.parse(context[:movie2])
    assert "Total Recall (2012/I) (TV)" = full_title
    %NMDB.Movie{full_title: full_title} = NMDB.Movie.parse(context[:series_main])
    assert "\"Fawlty Towers\" (1975)" = full_title
    %NMDB.Movie{full_title: full_title} = NMDB.Movie.parse(context[:series_episode])
    assert "\"Fawlty Towers\" (1975) {Basil the Rat (#2.6)}" = full_title
  end

  test "extract_full_year", context do
    %NMDB.Movie{full_year: full_year} = NMDB.Movie.parse(context[:movie1])
    assert "1990" = full_year
    %NMDB.Movie{full_year: full_year} = NMDB.Movie.parse(context[:movie2])
    assert "2012" = full_year
    %NMDB.Movie{full_year: full_year} = NMDB.Movie.parse(context[:series_main])
    assert "1975-1979" = full_year
    %NMDB.Movie{full_year: full_year} = NMDB.Movie.parse(context[:series_episode])
    assert "1979" = full_year
  end

  test "extract_title", context do
    %NMDB.Movie{title: title} = NMDB.Movie.parse(context[:movie1])
    assert "Total Recall" = title
    %NMDB.Movie{title: title} = NMDB.Movie.parse(context[:movie2])
    assert "Total Recall" = title
    %NMDB.Movie{title: title} = NMDB.Movie.parse(context[:series_main])
    assert "\"Fawlty Towers\"" = title
    %NMDB.Movie{title: title} = NMDB.Movie.parse(context[:series_episode])
    assert "\"Fawlty Towers\"" = title
  end

  test "extract_title_category", context do
    %NMDB.Movie{title_category: title_category} = NMDB.Movie.parse(context[:movie1])
    assert "" = title_category
    %NMDB.Movie{title_category: title_category} = NMDB.Movie.parse(context[:movie2])
    assert "TV" = title_category
    %NMDB.Movie{title_category: title_category} = NMDB.Movie.parse(context[:series_main])
    assert "TVS" = title_category
    %NMDB.Movie{title_category: title_category} = NMDB.Movie.parse(context[:series_episode])
    assert "TVS" = title_category
  end

  test "extract_title_year", context do
    %NMDB.Movie{title_year: title_year} = NMDB.Movie.parse(context[:movie1])
    assert "1990" = title_year
    %NMDB.Movie{title_year: title_year} = NMDB.Movie.parse(context[:movie2])
    assert "2012/I" = title_year
    %NMDB.Movie{title_year: title_year} = NMDB.Movie.parse(context[:series_main])
    assert "1975" = title_year
    %NMDB.Movie{title_year: title_year} = NMDB.Movie.parse(context[:series_episode])
    assert "1975" = title_year
  end

  test "extract_episode_parent_title", context do
    %NMDB.Movie{episode_parent_title: episode_parent_title} = NMDB.Movie.parse(context[:series_episode])
    assert "\"Fawlty Towers\" (1975)" = episode_parent_title
  end

  test "extract_episode_name", context do
    %NMDB.Movie{episode_name: episode_name} = NMDB.Movie.parse(context[:series_episode])
    assert "Basil the Rat" = episode_name
  end

  test "extract_episode_season", context do
    %NMDB.Movie{episode_season: episode_season} = NMDB.Movie.parse(context[:series_episode])
    assert "2" = episode_season
  end

  test "extract_episode_episode", context do
    %NMDB.Movie{episode_episode: episode_episode} = NMDB.Movie.parse(context[:series_episode])
    assert "6" = episode_episode
  end
end
