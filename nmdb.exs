movieids = NMDB.IDs.run
:observer.start
IO.puts("Memory: #{:erlang.memory(:binary)}")
NMDB.IDs.load_file(movieids, "data/movies_ids.dat")
IO.puts("Memory: #{:erlang.memory(:binary)}")
NMDB.Movie.parse_file(movieids, "data/movies.list.dat", "output/outputmovie.dat", "output/outputyears.dat")
IO.puts("Memory: #{:erlang.memory(:binary)}")

#peopleids = NMDB.IDs.run
#movieids = NMDB.IDs.run

#NMDB.IDs.load_file(peopleids, "person_ids.tab")

#send peopleids, {:inspect}
#send movieids, {:inspect}
#value = NMDB.IDs.get(peopleids)
#IO.puts "Got: #{value}"
#NMDB.IDs.put peopleids, "hello world"
#value = NMDB.IDs.get(peopleids)
#IO.puts "Got: #{value}"
#NMDB.IDs.put(movieids, "Something else")
#value = NMDB.IDs.get(peopleids)
#IO.puts "Got: #{value}"
#value = NMDB.IDs.get(movieids)
#IO.puts "Got: #{value}"
#
#send peopleids, {:inspect}
#send movieids, {:inspect}
