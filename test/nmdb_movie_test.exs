defmodule NMDBTest.Movie do
  use ExUnit.Case
  doctest NMDB.Movie

  setup do
    pid = NMDB.Movie.run
    movie1 = "Total Recall (1990)\t\t\t\t\t1990\n"
    movie2 = "Total Recall (2012/I) (TV)\t\t\t\t\t2012\n"
    movie3 = "Total Recall (2012/II) (VG)\t\t\t\t\t2012\n"
    suspended_movie1 = "Untotal Recall (1990) {{SUSPENDED}}\t\t\t\t\t1990\n"
    series_main = "\"Fawlty Towers\" (1975)\t\t\t\t\t1975-1979\n"
    series_main2 = "\"Naughty Towers\" (1975)\t\t\t\t\t1975-????\n"
    series_episode = "\"Fawlty Towers\" (1975) {Basil the Rat (#2.6)}\t\t1979\n"
    {:ok,
     [pid: pid,
      movie1: movie1,
      movie2: movie2,
      movie3: movie3,
      suspended_movie1: suspended_movie1,
      series_main: series_main,
      series_main2: series_main2,
      series_episode: series_episode
     ]}
  end

  test "extract_full_title", context do
    {%{full_title: full_title}, remaining} = NMDB.Movie.extract_full_title({%{}, context[:movie1]})
    assert "Total Recall (1990)" = full_title
    assert "1990" = remaining

    {%{full_title: full_title}, remaining} = NMDB.Movie.extract_full_title({%{}, context[:series_main]})
    assert "\"Fawlty Towers\" (1975)" = full_title
    assert "1975-1979" = remaining

    {%{full_title: full_title}, remaining} = NMDB.Movie.extract_full_title({%{}, context[:series_main2]})
    assert "\"Naughty Towers\" (1975)" = full_title
    assert "1975-????" = remaining

    {%{full_title: full_title}, remaining} = NMDB.Movie.extract_full_title({%{}, context[:series_episode]})
    assert "\"Fawlty Towers\" (1975) {Basil the Rat (#2.6)}" = full_title
    assert "1979" = remaining
  end
  
  test "extract_full_year" do
    {%{full_year: full_year}, remaining} = NMDB.Movie.extract_full_year({%{}, "1990"})
    assert "1990" = full_year
    assert nil == remaining

    {%{full_year: full_year}, remaining} = NMDB.Movie.extract_full_year({%{}, "1975-1979"})
    assert "1975-1979" = full_year
    assert nil == remaining

    {%{full_year: full_year}, remaining} = NMDB.Movie.extract_full_year({%{}, "1975-????"})
    assert "1975-????" = full_year
    assert nil == remaining
  end
  
  test "prepare_title" do
    {_, remaining} = NMDB.Movie.prepare_title({%{full_title: "Total Recall (1990)"}, nil})
    assert "Total Recall (1990)" = remaining
  end
  
  test "extract_episode" do
    {%{is_episode: is_episode}, remaining} = NMDB.Movie.extract_episode({%{}, "Total Recall (1990)"})
    assert false == is_episode
    assert "Total Recall (1990)" = remaining

    {%{is_episode: is_episode}, remaining} = NMDB.Movie.extract_episode({%{}, "\"Fawlty Towers\" (1975) {Basil the Rat (#2.6)}"})
    assert true == is_episode
  end

  test "extract_episode_parent_title" do
    {%{episode_parent_title: episode_parent_title}, _} =
      NMDB.Movie.extract_episode_parent_title({%{}, {"\"Fawlty Towers\" (1975)", "Basil the Rat (#2.6)"}})
    assert "\"Fawlty Towers\" (1975)" = episode_parent_title
  end

  test "extract_episode_season" do
    {%{episode_season: episode_season}, _} =
      NMDB.Movie.extract_episode_season({%{}, {"\"Fawlty Towers\" (1975)", "Basil the Rat (#2.6)"}})
    assert "2" = episode_season
  end

  test "extract_episode_episode" do
    {%{episode_episode: episode_episode}, {_, episode_data}} =
      NMDB.Movie.extract_episode_episode({%{}, {"\"Fawlty Towers\" (1975)", "Basil the Rat (#2.6)"}})
    assert "6" = episode_episode
    assert "Basil the Rat " = episode_data
  end

  test "extract_episode_name" do
    {%{episode_name: episode_name}, {_, episode_data}} =
      NMDB.Movie.extract_episode_name({%{}, {"\"Fawlty Towers\" (1975)", "Basil the Rat "}})
    assert "Basil the Rat" = episode_name
    assert "" = episode_data
  end

  test "restore_title" do
    {_, remaining_title} =
      NMDB.Movie.restore_title({%{}, {"\"Fawlty Towers\" (1975)", ""}})
    assert "\"Fawlty Towers\" (1975)" = remaining_title
  end

  test "extract_title_category" do
    {%{title_category: title_category}, remaining} =
      NMDB.Movie.extract_title_category({%{}, "Total Recall (1990)"})
    assert "" = title_category
    assert "Total Recall (1990)" = remaining

    {%{title_category: title_category}, remaining} =
      NMDB.Movie.extract_title_category({%{}, "Total Recall (2012/I) (TV)"})
    assert "TV" = title_category
    assert "Total Recall (2012/I)" = remaining

    {%{title_category: title_category}, remaining} =
      NMDB.Movie.extract_title_category({%{}, "Total Recall (2012/II) (VG)"})
    assert "VG" = title_category
    assert "Total Recall (2012/II)" = remaining

    {%{title_category: title_category}, remaining} =
      NMDB.Movie.extract_title_category({%{}, "\"Fawlty Towers\" (1975)"})
    assert "TVS" = title_category
    assert "\"Fawlty Towers\" (1975)" = remaining
  end
  
  test "extract_title_year" do
    {%{title_year: title_year}, remaining} =
      NMDB.Movie.extract_title_year({%{}, "Total Recall (1990)"})
    assert "1990" = title_year
    assert "Total Recall" = remaining

    {%{title_year: title_year}, remaining} =
      NMDB.Movie.extract_title_year({%{}, "Total Recall (2012/I)"})
    assert "2012/I" = title_year
    assert "Total Recall" = remaining

    {%{title_year: title_year}, remaining} =
      NMDB.Movie.extract_title_year({%{}, "Total Recall (2012/II)"})
    assert "2012/II" = title_year
    assert "Total Recall" = remaining

    {%{title_year: title_year}, remaining} =
      NMDB.Movie.extract_title_year({%{}, "\"Fawlty Towers\" (1975)"})
    assert "1975" = title_year
    assert "\"Fawlty Towers\"" = remaining
  end

  test "extract_title" do
    {%{title: title}, remaining} =
      NMDB.Movie.extract_title({%{}, "Total Recall"})
    assert "Total Recall" = title
    assert "" = remaining

    {%{title: title}, remaining} =
      NMDB.Movie.extract_title({%{}, "\"Fawlty Towers\""})
    assert "\"Fawlty Towers\"" = title
    assert "" = remaining
  end

  test "extract_year_single" do
    {%{year_open_end: year_open_end, years: years}, _} = NMDB.Movie.extract_year_single({%{}, "1990"})
    assert false == year_open_end
    assert 1990..1990 == years
  end

  test "extract_year_closed" do
    {%{year_open_end: year_open_end, years: years}, _} = NMDB.Movie.extract_year_closed({%{}, "1975-1979"})
    assert false == year_open_end
    assert 1975..1979 == years
  end
    
  test "extract_year_open" do
    this_year = DateTime.utc_now.year
    
    {%{year_open_end: year_open_end, years: years}, _} = NMDB.Movie.extract_year_open({%{}, "1975-????"})
    assert true == year_open_end
    assert 1975..this_year == years
  end

  test "extract_suspended" do
    {%{suspended: suspended}, _} = NMDB.Movie.extract_suspended({%{}, "Total Recall (1991)"})
    assert false == suspended
    {%{suspended: suspended}, _} = NMDB.Movie.extract_suspended({%{}, "Untotal Recall (1991) {{SUSPENDED}}"})
    assert true == suspended
    {%{suspended: suspended}, _} = NMDB.Movie.extract_suspended({%{}, "Untotal Recall (1991) {{SUSPEND}}"})
    assert true == suspended
  end
  
  test "parsed_extract_suspended", context do
    %NMDB.Movie{suspended: suspended} = NMDB.Movie.parse(context[:movie1])
    assert false == suspended
    %NMDB.Movie{suspended: suspended} = NMDB.Movie.parse(context[:suspended_movie1])
    assert true == suspended
  end
  
  test "parsed_extract_episode_parent_title", context do
    %NMDB.Movie{episode_parent_title: episode_parent_title} = NMDB.Movie.parse(context[:series_episode])
    assert "\"Fawlty Towers\" (1975)" = episode_parent_title
  end

  test "parsed_extract_episode_name", context do
    %NMDB.Movie{episode_name: episode_name} = NMDB.Movie.parse(context[:series_episode])
    assert "Basil the Rat" = episode_name
  end

  test "parsed_extract_episode_season", context do
    %NMDB.Movie{episode_season: episode_season} = NMDB.Movie.parse(context[:series_episode])
    assert "2" = episode_season
  end

  test "parsed_extract_episode_episode", context do
    %NMDB.Movie{episode_episode: episode_episode} = NMDB.Movie.parse(context[:series_episode])
    assert "6" = episode_episode
  end

  test "parsed_extract_year", context do
    this_year = DateTime.utc_now.year
    
    %NMDB.Movie{year_open_end: year_open_end, years: years} = NMDB.Movie.parse(context[:movie1])
    assert false == year_open_end
    assert 1990..1990 == years

    %NMDB.Movie{year_open_end: year_open_end, years: years} = NMDB.Movie.parse(context[:series_main])
    assert false == year_open_end
    assert 1975..1979 == years

    %NMDB.Movie{year_open_end: year_open_end, years: years} = NMDB.Movie.parse(context[:series_main2])
    assert true == year_open_end
    assert 1975..this_year == years
  end

  test "parsed_extract_full_title", context do
    %NMDB.Movie{full_title: full_title} = NMDB.Movie.parse(context[:movie1])
    assert "Total Recall (1990)" = full_title
    %NMDB.Movie{full_title: full_title} = NMDB.Movie.parse(context[:movie2])
    assert "Total Recall (2012/I) (TV)" = full_title
    %NMDB.Movie{full_title: full_title} = NMDB.Movie.parse(context[:series_main])
    assert "\"Fawlty Towers\" (1975)" = full_title
    %NMDB.Movie{full_title: full_title} = NMDB.Movie.parse(context[:series_episode])
    assert "\"Fawlty Towers\" (1975) {Basil the Rat (#2.6)}" = full_title
  end

  test "parsed_extract_full_year", context do
    %NMDB.Movie{full_year: full_year} = NMDB.Movie.parse(context[:movie1])
    assert "1990" = full_year
    %NMDB.Movie{full_year: full_year} = NMDB.Movie.parse(context[:movie2])
    assert "2012" = full_year
    %NMDB.Movie{full_year: full_year} = NMDB.Movie.parse(context[:series_main])
    assert "1975-1979" = full_year
    %NMDB.Movie{full_year: full_year} = NMDB.Movie.parse(context[:series_episode])
    assert "1979" = full_year
  end

  test "parsed_extract_title", context do
    %NMDB.Movie{title: title} = NMDB.Movie.parse(context[:movie1])
    assert "Total Recall" = title
    %NMDB.Movie{title: title} = NMDB.Movie.parse(context[:movie2])
    assert "Total Recall" = title
    %NMDB.Movie{title: title} = NMDB.Movie.parse(context[:series_main])
    assert "\"Fawlty Towers\"" = title
    %NMDB.Movie{title: title} = NMDB.Movie.parse(context[:series_episode])
    assert "\"Fawlty Towers\"" = title
  end

  test "parsed_extract_title_category", context do
    %NMDB.Movie{title_category: title_category} = NMDB.Movie.parse(context[:movie1])
    assert "" = title_category
    %NMDB.Movie{title_category: title_category} = NMDB.Movie.parse(context[:movie2])
    assert "TV" = title_category
    %NMDB.Movie{title_category: title_category} = NMDB.Movie.parse(context[:series_main])
    assert "TVS" = title_category
    %NMDB.Movie{title_category: title_category} = NMDB.Movie.parse(context[:series_episode])
    assert "TVS" = title_category
  end

  test "parsed_extract_title_year", context do
    %NMDB.Movie{title_year: title_year} = NMDB.Movie.parse(context[:movie1])
    assert "1990" = title_year
    %NMDB.Movie{title_year: title_year} = NMDB.Movie.parse(context[:movie2])
    assert "2012/I" = title_year
    %NMDB.Movie{title_year: title_year} = NMDB.Movie.parse(context[:series_main])
    assert "1975" = title_year
    %NMDB.Movie{title_year: title_year} = NMDB.Movie.parse(context[:series_episode])
    assert "1975" = title_year
  end
end
