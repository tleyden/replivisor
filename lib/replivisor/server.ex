defmodule Replivisor.Server do
	use GenServer.Behaviour
	alias Replivisor.Config, as: Config

	def start_link do
		:gen_server.start_link({:local, __MODULE__}, __MODULE__, HashDict.new, [])	
	end

	def init(state) do

		# get the list of dbs we need to monitor from config

		couchdb = Config.CouchDB.new(url: "myurl")
		IO.puts "couchdb: #{inspect(couchdb)}"

		# loop over each one and start monitoring

		# create a hashdict keyed on monitoring ref



		IO.puts "init called with state: #{inspect(state)}"
		db = init_db()
		start_ref = init_track_changes(db)
		state = HashDict.put(state, start_ref, :empty)
		IO.puts "init returning state: #{inspect(state)}"
		{ :ok, state }
	end

	def handle_info(msg, state) do
		# example msg
		# {:change,#Reference<0.0.0.535>,
		# {[{"seq",13182},{"id","00175475-1292-419A-B0C6-B1D457F29528"},{"changes",[{[{"rev","8-2eb257db8a15ada29cfda2eabe3b695d"}]}]}]}}
		IO.puts "handle_info called with: #{inspect(msg)}"
		{ :noreply, state }
	end

	def init_db do
		options = []
		server = :couchbeam.server_connection("localhost", 5984, "", options)
		_result = :couchbeam.server_info(server)
		db_options = []
		{:ok, db} = :couchbeam.open_db(server, "sigdb", db_options)
		db
	end

	def init_track_changes(db) do
		{:ok, last_seq, _rows} = :couchbeam_changes.fetch(db, [])
		since_tuple = {:since,last_seq}
		IO.puts "monitoring changes starting at seq: #{last_seq}"
		changes_options = [:continuous, :heartbeat, since_tuple]
		server_pid = :erlang.whereis(__MODULE__)
		IO.puts "server_pid: #{inspect(server_pid)}"
		{:ok, start_ref, change_pid} = :couchbeam_changes.stream(db, server_pid, changes_options)
		IO.puts "start_ref: #{inspect(start_ref)} change_pid: #{inspect(change_pid)}"
		start_ref
	end

end