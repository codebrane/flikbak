require 'json'
require 'open-uri'
require './flickr/utils'
require './flickr/model/flickrobject'
require './flickr/model/user'
require './flickr/model/photoset'
require './flickr/model/photo'
require './flickr/model/photocomment'
require './flickr/model/userprofile'
require './flickr/model/contact'
require './flickr/model/group'
require './flickr/model/collection'

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
    
  def get_contacts
    access_token = read_access_token(@data_dir)
    oauth_token_secret = read_oauth_token_secret(@data_dir)

    oauth_nonce = nonce
    oauth_timestamp = now

    base_string = "GET&"
    base_string += CGI.escape("https://api.flickr.com/services/rest")
    base_string += "&"
    params = "format=json"
    params += "&method=flickr.contacts.getList"
    params += "&nojsoncallback=1"
    params += "&oauth_consumer_key=#{@api_key}"
    params += "&oauth_nonce=#{oauth_nonce}"
    params += "&oauth_signature_method=#{OAUTH_SIGNATURE_METHOD}"
    params += "&oauth_timestamp=#{oauth_timestamp}"
    params += "&oauth_token=#{access_token}"
    params += "&oauth_version=#{OAUTH_VERSION}"
    base_string += CGI.escape(params)
    signature = sign("#{@secret}&#{oauth_token_secret}", base_string)
    url = "https://api.flickr.com/services/rest?#{params}&oauth_signature=#{CGI.escape(signature)}&method=flickr.contacts.getList"
    rest_response = call_service(url)
    json = JSON.parse(rest_response)
    contacts = []
    json['contacts']['contact'].each do |contact|
      user_contact = Contact.new
      user_contact.nsid = contact['nsid']
      user_contact.username = contact['username']
      user_contact.realname = contact['realname']
      user_contact.friend = contact['friend']
      user_contact.family = contact['family']
      user_contact.path_alias = contact['path_alias']
      user_contact.location = contact['location']
      contacts.push(user_contact)
    end
    contacts
  end # get_contacts
  
  def get_groups(user_id)
    access_token = read_access_token(@data_dir)
    oauth_token_secret = read_oauth_token_secret(@data_dir)

    oauth_nonce = nonce
    oauth_timestamp = now

    base_string = "GET&"
    base_string += CGI.escape("https://api.flickr.com/services/rest")
    base_string += "&"
    params = "format=json"
    params += "&method=flickr.people.getGroups"
    params += "&nojsoncallback=1"
    params += "&oauth_consumer_key=#{@api_key}"
    params += "&oauth_nonce=#{oauth_nonce}"
    params += "&oauth_signature_method=#{OAUTH_SIGNATURE_METHOD}"
    params += "&oauth_timestamp=#{oauth_timestamp}"
    params += "&oauth_token=#{access_token}"
    params += "&oauth_version=#{OAUTH_VERSION}"
    # need to double escape the nsid as it is XXXXX@YY
    # need XXXXX%2540YY instead of XXXXX%40YY
    params += "&user_id=#{CGI.escape(user_id)}"
    base_string += CGI.escape(params)
    signature = sign("#{@secret}&#{oauth_token_secret}", base_string)
    url = "https://api.flickr.com/services/rest?#{params}&oauth_signature=#{CGI.escape(signature)}&method=flickr.people.getGroups"
    rest_response = call_service(url)
    json = JSON.parse(rest_response)
    groups = []
    json['groups']['group'].each do |group|
      user_group = Group.new
      user_group.nsid = group['nsid']
      user_group.name = group['name']
      user_group.is_moderator = group['is_moderator']
      user_group.is_admin = group['is_admin']
      groups.push(user_group)
    end
    groups
  end # get_groups
  
  def get_photosets(user_id)
    access_token = read_access_token(@data_dir)
    oauth_token_secret = read_oauth_token_secret(@data_dir)

    oauth_nonce = nonce
    oauth_timestamp = now

    url_rest = "https://api.flickr.com/services/rest"
    url_rest += "?api_key=#{@api_key}"
    url_rest += "&user_id=#{user_id}"
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
      photoset.ownername = photoset_json["ownername"]
      photosets.push(photoset)
    end
    
    photosets
  end # get_photosets
  
  def get_photos_in_photoset(user_id, photoset)
    access_token = read_access_token(@data_dir)
    oauth_token_secret = read_oauth_token_secret(@data_dir)

    oauth_nonce = nonce
    oauth_timestamp = now
    
    extras = "license, date_upload, date_taken, tags"

    url_rest = "https://api.flickr.com/services/rest"
    url_rest += "?api_key=#{@api_key}"
    url_rest += "&user_id=#{user_id}"
    url_rest += "&photoset_id=#{photoset.id}"
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
    photoset.ownername = json['photoset']['ownername']
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
    photo.no_of_comments = json["photo"]["comments"]["_content"]
    if (photo.no_of_comments != "0")
      get_photo_comments(photo)
    end
  end # get_photo_info

  def get_photo_comments(photo)
    access_token = read_access_token(@data_dir)
    oauth_token_secret = read_oauth_token_secret(@data_dir)

    oauth_nonce = nonce
    oauth_timestamp = now
    
    url_rest = "https://api.flickr.com/services/rest"
    url_rest += "?api_key=#{@api_key}"
    url_rest += "&photo_id=#{photo.id}"
    url_rest += "&secret=#{photo.secret}"
    url_rest += "&format=json"
    url_rest += "&nojsoncallback=1"
    url_rest += "&oauth_timestamp=#{oauth_timestamp}"
    url_rest += "&oauth_version=#{OAUTH_VERSION}"
    url_rest += "&oauth_token=#{access_token}"
    url_rest += "&method=flickr.photos.comments.getList"
    rest_response = call_service(url_rest)
    json = JSON.parse(rest_response)
    json["comments"]["comment"].each do |comment|
      photocomment = PhotoComment.new
      photocomment.date_created = comment['datecreate']
      photocomment.author = comment['authorname']
      photocomment.text = comment['_content']
      photocomment.author_url = get_user_profile_url(comment['author'])
      photocomment.user_profile = get_user_profile(comment['author'])
      photocomment.user_profile.realname = get_user_info(photocomment.user_profile.id)
      photo.add_comment(photocomment)
    end
  end # get_photo_comments
  
  def get_user_profile(userid)
    access_token = read_access_token(@data_dir)
    oauth_token_secret = read_oauth_token_secret(@data_dir)

    oauth_nonce = nonce
    oauth_timestamp = now
    
    url_rest = "https://api.flickr.com/services/rest"
    url_rest += "?api_key=#{@api_key}"
    url_rest += "&user_id=#{userid}"
    url_rest += "&format=json"
    url_rest += "&nojsoncallback=1"
    url_rest += "&oauth_timestamp=#{oauth_timestamp}"
    url_rest += "&oauth_version=#{OAUTH_VERSION}"
    url_rest += "&oauth_token=#{access_token}"
    url_rest += "&method=flickr.profile.getProfile"
    rest_response = call_service(url_rest)
    json = JSON.parse(rest_response)
    user_profile = UserProfile.new
    user_profile.id = json['profile']['id']
    user_profile.nsid = json['profile']['nsid']
    user_profile.join_date = json['profile']['join_date']
    user_profile.occupation = json['profile']['occupation']
    user_profile.hometown = json['profile']['hometown']
    user_profile.showcase_set = json['profile']['showcase_set']
    user_profile.profile_description = json['profile']['profile_description']
    user_profile.facebook = json['profile']['facebook']
    user_profile.twitter = json['profile']['twitter']
    user_profile.tumblr = json['profile']['tumblr']
    user_profile.instagram = json['profile']['instagram']
    user_profile.pinterest = json['profile']['pinterest']
    user_profile  
  end # get_user_profile

  def get_user_profile_url(userid)
    access_token = read_access_token(@data_dir)
    oauth_token_secret = read_oauth_token_secret(@data_dir)

    oauth_nonce = nonce
    oauth_timestamp = now
    
    url_rest = "https://api.flickr.com/services/rest"
    url_rest += "?api_key=#{@api_key}"
    url_rest += "&user_id=#{userid}"
    url_rest += "&format=json"
    url_rest += "&nojsoncallback=1"
    url_rest += "&oauth_timestamp=#{oauth_timestamp}"
    url_rest += "&oauth_version=#{OAUTH_VERSION}"
    url_rest += "&oauth_token=#{access_token}"
    url_rest += "&method=flickr.urls.getUserProfile"
    rest_response = call_service(url_rest)
    json = JSON.parse(rest_response)
    if json['user'].nil?
      json['message']
    else
      json['user']['url']
    end
  end # get_user_profile_url
  
  def get_user_info(userid)
    access_token = read_access_token(@data_dir)
    oauth_token_secret = read_oauth_token_secret(@data_dir)

    oauth_nonce = nonce
    oauth_timestamp = now

    base_string = "GET&"
    base_string += CGI.escape("https://api.flickr.com/services/rest")
    base_string += "&"
    params = "format=json"
    params += "&method=flickr.people.getInfo"
    params += "&nojsoncallback=1"
    params += "&oauth_consumer_key=#{@api_key}"
    params += "&oauth_nonce=#{oauth_nonce}"
    params += "&oauth_signature_method=#{OAUTH_SIGNATURE_METHOD}"
    params += "&oauth_timestamp=#{oauth_timestamp}"
    params += "&oauth_token=#{access_token}"
    params += "&oauth_version=#{OAUTH_VERSION}"
    params += "&user_id=#{userid}"
    base_string += CGI.escape(params)
    signature = sign("#{@secret}&#{oauth_token_secret}", base_string)
    url = "https://api.flickr.com/services/rest?#{params}&oauth_signature=#{CGI.escape(signature)}&method=flickr.people.getInfo"
    rest_response = call_service(url)
    json = JSON.parse(rest_response)
    if (json['person'].nil?)
      json['message']
    else
      json['person']['realname']['_content'] unless json['person']['realname'].nil?
    end
  end # get_user_info
  
  def get_photos_not_in_sets
    access_token = read_access_token(@data_dir)
    oauth_token_secret = read_oauth_token_secret(@data_dir)

    oauth_nonce = nonce
    oauth_timestamp = now
    
    extras = "description,license,date_upload,date_taken,owner_name,original_format,last_update,geo,tags,views"

    base_string = "GET&"
    base_string += CGI.escape("https://api.flickr.com/services/rest")
    base_string += "&"
    params = "extras=#{CGI.escape(extras)}"
    params += "&format=json"
    params += "&method=flickr.photos.getNotInSet"
    params += "&nojsoncallback=1"
    params += "&oauth_consumer_key=#{@api_key}"
    params += "&oauth_nonce=#{oauth_nonce}"
    params += "&oauth_signature_method=#{OAUTH_SIGNATURE_METHOD}"
    params += "&oauth_timestamp=#{oauth_timestamp}"
    params += "&oauth_token=#{access_token}"
    params += "&oauth_version=#{OAUTH_VERSION}"
    base_string += CGI.escape(params)
    signature = sign("#{@secret}&#{oauth_token_secret}", base_string)
    url = "https://api.flickr.com/services/rest?#{params}&oauth_signature=#{CGI.escape(signature)}&method=flickr.photos.getNotInSet"
    rest_response = call_service(url)
    json = JSON.parse(rest_response)
    photos = []
    json['photos']['photo'].each do |photo|
      flickr_photo = Photo.new
      flickr_photo.id = photo['id']
      flickr_photo.secret = photo['secret']
      flickr_photo.server = photo['server']
      flickr_photo.farm = photo['farm']
      flickr_photo.title = photo['title']
      flickr_photo.dateupload = photo['dateupload']
      flickr_photo.datetaken = photo['datetaken']
      flickr_photo.tags = photo['tags']
      flickr_photo.views = photo['views']
      get_photo_info(flickr_photo)
      photos.push(flickr_photo)
    end
    photos
  end # get_user_info
  
  def get_collections(user_id)
    access_token = read_access_token(@data_dir)
    oauth_token_secret = read_oauth_token_secret(@data_dir)

    oauth_nonce = nonce
    oauth_timestamp = now
    
    url_rest = "https://api.flickr.com/services/rest"
    url_rest += "?api_key=#{@api_key}"
    url_rest += "&user_id=#{user_id}"
    url_rest += "&format=json"
    url_rest += "&nojsoncallback=1"
    url_rest += "&oauth_timestamp=#{oauth_timestamp}"
    url_rest += "&oauth_version=#{OAUTH_VERSION}"
    url_rest += "&oauth_token=#{access_token}"
    url_rest += "&method=flickr.collections.getTree"
    rest_response = call_service(url_rest)
    json = JSON.parse(rest_response)
    collections = []
    json['collections']['collection'].each do |collection|
      flickr_collection = Collection.new
      flickr_collection.id = collection['id']
      flickr_collection.title = collection['title']
      flickr_collection.description = collection['description']
      photosets = []
      if !collection['set'].nil?
        collection['set'].each do |set| 
          photoset = PhotoSet.new
          photoset.id = set['id']
          photoset.title = set['title']
          photoset.description = set['description']
          photosets.push(photoset)
        end
        flickr_collection.sets = photosets
      end
      collections.push(flickr_collection)
    end
    collections
  end # get_collections
  
  def download_photo(photo_url, photo_path)
    # https://stackoverflow.com/questions/2263540/how-do-i-download-a-binary-file-over-http
    File.open(photo_path, "wb") do |saved_file|
      open(photo_url, "rb") do |read_file|
        saved_file.write(read_file.read)
      end
    end
  end # download_photo
  
  def create_metadata_file(metadata, filename)
    File.open(filename, "wb") do |json_file|
      json_file.write(metadata.to_json)
    end
  end # create_contacts_metadata_file
  
  def get_original_photo_url(photo)
    "https://farm#{photo.farm}.staticflickr.com/#{photo.server}/#{photo.id}_#{photo.originalsecret}_o.#{photo.originalformat}"
  end # get_original_photo_url
end