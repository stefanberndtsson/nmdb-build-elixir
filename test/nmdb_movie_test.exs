defmodule NMDBTest.Movie do
  use ExUnit.Case
  doctest NMDB.Movie

  setup do
    pid = NMDB.Movie.run
    movie1 = "Total Recall (1990)\t\t\t\t\t1990"
    movie2 = "Total Recall (2012/I)\t\t\t\t\t2012"
    movie3 = "Total Recall (2012/II)\t\t\t\t\t2012"
    series_main = "\"Fawlty Towers\" (1975)\t\t\t\t\t1975-1979"
    series_episode = "\"Fawlty Towers\" (1975) {Basil the Rat (#2.6)}\t\t1979"
    {:ok, [pid: pid, movie1: movie1, movie2: movie2, movie3: movie3, series_main: series_main, series_episode: series_episode]}
  end
  
  test "extract_full_title", context do
    %NMDB.Movie{full_title: full_title} = NMDB.Movie.parse(context[:movie1])
    assert "Total Recall (1990)" = full_title
    %NMDB.Movie{full_title: full_title} = NMDB.Movie.parse(context[:movie2])
    assert "Total Recall (2012/I)" = full_title
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
end
