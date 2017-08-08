require 'json'
require 'open-uri'
require './flickr/utils'
require './flickr/model/flickrobject'
require './flickr/model/user'
require './flickr/model/photoset'
require './flickr/model/photo'

class Flickr
  OAUTH_SIGNATURE_METHOD = "HMAC-SHA1"
  OAUTH_VERSION = "1.0"
  OAUTH_CALLBACK = "oob"
  
  attr_accessor :api_key, :secret, :data_dir
  
  def initialize(api_key, secret, data_dir)
    @api_key = api_key
    @secret = secret
    @data_dir = data_dir
  end
  
  def get_access_token
    oauth_nonce = nonce
    oauth_timestamp = now

    flickr_url = "https://www.flickr.com/services/oauth/request_token"
    base_string = "GET&#{CGI.escape(flickr_url)}&"
    params = "oauth_callback=#{OAUTH_CALLBACK}"
    params += "&oauth_consumer_key=#{@api_key}"
    params += "&oauth_nonce=#{oauth_nonce}"
    params += "&oauth_signature_method=#{OAUTH_SIGNATURE_METHOD}"
    params += "&oauth_timestamp=#{oauth_timestamp}"
    params += "&oauth_version=#{OAUTH_VERSION}"
    base_string += CGI.escape(params)
    signature = sign("#{@secret}&", base_string)
    url_request_token = "#{flickr_url}?#{params}&oauth_signature=#{CGI.escape(signature)}&oauth_callback=#{OAUTH_CALLBACK}"
    request_token_response = call_service(url_request_token)
    parts = request_token_response.split("&")
    oauth_token = parts[1].split("=")[1]
    oauth_token_secret = parts[2].split("=")[1]
    p "Please authorise FlikBack. The browser will open. Copy/paste the code. Press any key to open the browser."
    STDIN.gets
    system('open', "https://www.flickr.com/services/oauth/authorize?oauth_token=#{oauth_token}")
    oauth_verifier = STDIN.gets.chomp

    oauth_nonce = nonce
    oauth_timestamp = now
    flickr_url = "https://www.flickr.com/services/oauth/access_token"
    base_string = "GET&#{CGI.escape(flickr_url)}&"
    params = "oauth_consumer_key=#{@api_key}"
    params += "&oauth_nonce=#{oauth_nonce}"
    params += "&oauth_signature_method=#{OAUTH_SIGNATURE_METHOD}"
    params += "&oauth_timestamp=#{oauth_timestamp}"
    params += "&oauth_token=#{oauth_token}"
    params += "&oauth_verifier=#{oauth_verifier}"
    params += "&oauth_version=#{OAUTH_VERSION}"
    base_string += CGI.escape(params)
    signature = sign("#{@secret}&#{oauth_token_secret}", base_string)
    url_access_token = "#{flickr_url}?#{params}&oauth_signature=#{CGI.escape(signature)}"
    request_token_response = call_service(url_access_token)
    parts = request_token_response.split("&")
    fullname = parts[0].split("=")[1]
    access_token = parts[1].split("=")[1]
    oauth_token_secret = parts[2].split("=")[1]
    user_nsid = parts[3].split("=")[1]
    username = parts[4].split("=")[1]
    File.write("#{@data_dir}/access_token", access_token)
    File.write("#{@data_dir}/oauth_token_secret", oauth_token_secret)
  end # get_access_token
  
  def login
    access_token = read_access_token(@data_dir)
    oauth_token_secret = read_oauth_token_secret(@data_dir)

    oauth_nonce = nonce
    oauth_timestamp = now

    base_string = "GET&"
    base_string += CGI.escape("https://api.flickr.com/services/rest")
    base_string += "&"
    params = "format=json"
    params += "&method=flickr.test.login"
    params += "&nojsoncallback=1"
    params += "&oauth_consumer_key=#{@api_key}"
    params += "&oauth_nonce=#{oauth_nonce}"
    params += "&oauth_signature_method=#{OAUTH_SIGNATURE_METHOD}"
    params += "&oauth_timestamp=#{oauth_timestamp}"
    params += "&oauth_token=#{access_token}"
    params += "&oauth_version=#{OAUTH_VERSION}"
    base_string += CGI.escape(params)
    signature = sign("#{@secret}&#{oauth_token_secret}", base_string)
    url_login = "https://api.flickr.com/services/rest?#{params}&oauth_signature=#{CGI.escape(signature)}&method=flickr.test.login"
    login_response = call_service(url_login)
    json = JSON.parse(login_response)
    user = User.new(json["user"]["id"], json["user"]["username"]["_content"], json["user"]["path_alias"])
  end # login
  
  def get_photosets
    access_token = read_access_token(@data_dir)
    oauth_token_secret = read_oauth_token_secret(@data_dir)

    oauth_nonce = nonce
    oauth_timestamp = now

    url_rest = "https://api.flickr.com/services/rest"
    url_rest += "?api_key=#{@api_key}"
    url_rest += "&user_id=9049153@N04"
    url_rest += "&format=json"
    url_rest += "&nojsoncallback=1"
    url_rest += "&oauth_timestamp=#{oauth_timestamp}"
    url_rest += "&oauth_version=#{OAUTH_VERSION}"
    url_rest += "&oauth_token=#{access_token}"
    url_rest += "&method=flickr.photosets.getList"
    rest_response = call_service(url_rest)
    photosets = []
    json = JSON.parse(rest_response)
    json["photosets"]["photoset"].each do |photoset_json|
      photoset = PhotoSet.new
      photoset.id = photoset_json["id"]
      photoset.primary = photoset_json["primary"]
      photoset.secret = photoset_json["secret"]
      photoset.server = photoset_json["server"]
      photoset.farm = photoset_json["farm"]
      photoset.photos = photoset_json["photos"]
      photoset.videos = photoset_json["videos"]
      photoset.title = photoset_json["title"]["_content"]
      photoset.description = photoset_json["description"]["_content"]
      photoset.count_views = photoset_json["count_views"]
      photoset.count_comments = photoset_json["count_comments"]
      photoset.date_create = photoset_json["date_create"]
      photoset.date_update = photoset_json["date_update"]
      photosets.push(photoset)
    end
    
    photosets
  end # get_photosets
  
  def get_photos_in_photoset(user_id, photoset_id)
    access_token = read_access_token(@data_dir)
    oauth_token_secret = read_oauth_token_secret(@data_dir)

    oauth_nonce = nonce
    oauth_timestamp = now
    
    extras = "license, date_upload, date_taken, tags"

    url_rest = "https://api.flickr.com/services/rest"
    url_rest += "?api_key=#{@api_key}"
    url_rest += "&user_id=#{user_id}"
    url_rest += "&photoset_id=#{photoset_id}"
    url_rest += "&extras=#{extras}"
    url_rest += "&format=json"
    url_rest += "&nojsoncallback=1"
    url_rest += "&oauth_timestamp=#{oauth_timestamp}"
    url_rest += "&oauth_version=#{OAUTH_VERSION}"
    url_rest += "&oauth_token=#{access_token}"
    url_rest += "&method=flickr.photosets.getPhotos"
    rest_response = call_service(url_rest)
    
    photos = []
    json = JSON.parse(rest_response)
    json["photoset"]["photo"].each do |flickr_photo|
      photo = Photo.new
      photo.id = flickr_photo["id"]
      photo.secret = flickr_photo["secret"]
      photo.server = flickr_photo["server"]
      photo.farm = flickr_photo["farm"]
      photo.title = flickr_photo["title"]
      photo.dateupload = flickr_photo["dateupload"]
      photo.datetaken = flickr_photo["datetaken"]
      photo.tags = flickr_photo["tags"]
      get_photo_info(photo)
      photos.push(photo)
    end
    
    photos
    
  end # get_photos_in_photoset
  
  def get_photo_info(photo)
    access_token = read_access_token(@data_dir)
    oauth_token_secret = read_oauth_token_secret(@data_dir)

    oauth_nonce = nonce
    oauth_timestamp = now
    
    extras = "license, date_upload, date_taken, tags"

    url_rest = "https://api.flickr.com/services/rest"
    url_rest += "?api_key=#{@api_key}"
    url_rest += "&photo_id=#{photo.id}"
    url_rest += "&secret=#{photo.secret}"
    url_rest += "&format=json"
    url_rest += "&nojsoncallback=1"
    url_rest += "&oauth_timestamp=#{oauth_timestamp}"
    url_rest += "&oauth_version=#{OAUTH_VERSION}"
    url_rest += "&oauth_token=#{access_token}"
    url_rest += "&method=flickr.photos.getInfo"
    rest_response = call_service(url_rest)
    json = JSON.parse(rest_response)
    photo.description = json["photo"]["description"]["_content"]
    photo.originalsecret = json["photo"]["originalsecret"]
    photo.originalformat = json["photo"]["originalformat"]
  end # get_photo_info
  
  def download_photo(photo_url, photo_path)
    # https://stackoverflow.com/questions/2263540/how-do-i-download-a-binary-file-over-http
    File.open(photo_path, "wb") do |saved_file|
      open(photo_url, "rb") do |read_file|
        saved_file.write(read_file.read)
      end
    end
  end # download_photo
  
  def create_photo_metadata_files(photo, dir)
    File.open("#{dir}/#{photo.title.gsub(/[\s,]/, "_")}.json", "wb") do |json_file|
      json_file.write(photo.to_json)
    end
  end # create_photo_metadata_files
  
end