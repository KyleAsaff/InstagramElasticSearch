require "sinatra"
require "instagram"
require "elasticsearch"

enable :sessions

es = Elasticsearch::Client.new log: true

CALLBACK_URL = "http://localhost:4567/oauth/callback"

Instagram.configure do |config|
  config.client_id = "3912bfb0304246bcb87c844d9f16ff71"
  config.client_secret = "c613a4f3f8404a04866c9010858a1bb8"
  # For secured endpoints only
  # config.client_ips = '<Comma separated list of IPs>'
end

get "/" do
  redirect Instagram.authorize_url(:redirect_uri => CALLBACK_URL)
end

get "/oauth/connect" do
  redirect Instagram.authorize_url(:redirect_uri => CALLBACK_URL)
end

get "/oauth/callback" do
  response = Instagram.get_access_token(params[:code], :redirect_uri => CALLBACK_URL)
  session[:access_token] = response.access_token
  redirect "/media_popular"
end

get "/media_popular" do
  10.times do 
    client = Instagram.client(:access_token => session[:access_token])
    for media_item in client.media_popular
      #YYYYMMDD
      created_time = media_item.created_time.to_i
      date = Time.at(created_time).to_datetime
      date = date.strftime("%Y%m%d")
      es.index  index: 'popular', type: 'media_item', id: media_item.id, body: { tags: media_item.tags, posix_time: media_item.created_time, date: date }
    end
  end
  "Done fetching most popular media"
end