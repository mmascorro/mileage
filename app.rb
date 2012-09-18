require 'sinatra'
require 'sinatra/reloader'
require 'sqlite3'

require 'dropbox_sdk'



db = SQLite3::Database.new( "mileage.db" )
db.results_as_hash = true

APP_KEY = 'jbmgaznc7uukml7'
APP_SECRET = 'oekmkvl3utz4occ'
ACCESS_TYPE = :app_folder

saved_session = nil
session  = nil



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

get '/config' do
	erb :config
end


#init the dropbox api
get '/dp/:type' do


	if saved_session == nil
		session = DropboxSession.new(APP_KEY,APP_SECRET)
	else
		session = DropboxSession.deserialize(saved_session)
	end

	

	if params[:type] == "backup"
		begin 
			dpClient = DropboxClient.new(session, ACCESS_TYPE)

			file = open('mileage.db')
			response = dpClient.put_file('/mileage.db', file,true)
			puts response.inspect

			@status = "Backup"

		rescue DropboxAuthError => e
			redirect to(uri("/dprquest/#{params[:type]}"))
		end
	end


	if params[:type] == "restore"
		begin
			dpClient = DropboxClient.new(session, ACCESS_TYPE)

			out = dpClient.get_file("/mileage.db")
			open('mileage.db', 'w') {|f| f.puts out }

			@status = "Restore"

		rescue DropboxAuthError => e
			redirect to(uri("/dprquest/#{params[:type]}"))
		end
	end

	
	erb :dropbox

end

#make new oauth request
get '/dprquest/:type' do
	session.get_request_token
	authorize_url = session.get_authorize_url(uri("/dpa/#{params[:type]}"))
	# "<a href=\"#{authorize_url}\">#{authorize_url}</a>"
	redirect to(authorize_url)

end


#handle oauth callback
get '/dpa/:type' do

	#params[:uid], params[:oauth_token]
	session.get_access_token
	saved_session = session.serialize
	redirect to(uri("/dp/#{params[:type]}"))

end
