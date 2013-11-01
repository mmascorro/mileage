require 'sinatra'
require 'sinatra/reloader'
require 'sqlite3'
require 'yaml'
require 'dropbox_sdk'



db = SQLite3::Database.new( "mileage.db" )
db.results_as_hash = true



get '/' do
	@rows = db.execute( "SELECT * FROM trips ORDER BY id desc" )
	erb :index
end


get '/trip/:id' do
	
	@trip = db.get_first_row("SELECT * FROM trips WHERE id = ?", params[:id])

	sql = "SELECT id, datetime(start_dt,'localtime') as start_dt, start_odometer, datetime(end_dt,'localtime') as end_dt, end_odometer, end_odometer-start_odometer as miles
	FROM legs
	WHERE trip_id = ?
	ORDER BY id desc"
	@legs = db.execute(sql, params[:id])


	erb :trip
end


post '/trip' do
	db.execute("insert into trips (name) values (?)", params[:name])
	redirect to('/')
end


post '/leg' do

	if params[:id]

		db.execute("UPDATE legs SET trip_id=?, start_dt=?, start_odometer=?, end_dt=?, end_odometer=? WHERE id=?", 
		
		params[:trip_id],
		params[:start_dt], params[:start_odometer], 
		params[:end_dt], params[:end_odometer],
		params[:id]
		)
	
		redirect to("trip/#{params[:trip_id]}")
	else
		db.execute("INSERT INTO legs (trip_id, start_dt,start_odometer,end_dt,end_odometer) VALUES (?,?,?,?,?)", 
		params[:trip_id], 
		params[:start_dt], params[:start_odometer], 
		params[:end_dt], params[:end_odometer]
		)
	
		redirect to("trip/#{params[:trip_id]}")

	end

	
end

get '/leg/:id' do

	sql = "SELECT id, trip_id, start_dt, start_odometer, end_dt, end_odometer
	FROM legs
	WHERE id = ?"
	@leg = db.get_first_row(sql, params[:id])
	
	erb :leg
	
end