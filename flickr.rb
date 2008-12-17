require 'digest/md5'
require 'open-uri'
require 'rexml/document'
require 'launcher'
require 'flickruser'
require 'flickrerror'
require 'photosetfactory'
require 'photoset'
require 'photofactory'

class Flickr
  PERM_READ = "read"
  PERM_WRITE = "write"
  PERM_DELETE = "delete"
  
  @@AUTH_API = "http://flickr.com/services/auth/?api_key="
  @@REST_API = "http://api.flickr.com/services/rest/?method="
  
  attr_reader :api_key, :secret
  
  def initialize(api_key, secret)
    @api_key = api_key
    @secret = secret
  end
  
  def user_authorise(perms, frob)
    api_sig = sig("#{@secret}api_key#{@api_key}frob#{frob}perms#{perms}")
    Launcher.open("#{@@AUTH_API}#{@api_key}&perms=#{perms}&frob=#{frob}&api_sig=#{api_sig}")
  end
  
  def get_frob
    api_sig = sig("#{@secret}api_key#{@api_key}methodflickr.auth.getFrob")
    api_url = "#{@@REST_API}flickr.auth.getFrob&api_key=#{@api_key}&api_sig=#{api_sig}"
    frob_node = REXML::XPath.first(REXML::Document.new(open(api_url).read), "//frob")
    frob_node.text
  end
  
  def get_token(frob)
    api_sig = sig("#{@secret}api_key#{@api_key}frob#{frob}methodflickr.auth.getToken")
    api_url = "#{@@REST_API}flickr.auth.getToken&api_key=#{@api_key}&frob=#{frob}&api_sig=#{api_sig}"
    get_user_details(REXML::Document.new(open(api_url).read))
  end
  
  def get_user(auth_token)
    api_sig = sig("#{@secret}api_key#{@api_key}auth_token#{auth_token}methodflickr.auth.checkToken")
    api_url = "#{@@REST_API}flickr.auth.checkToken&api_key=#{@api_key}&auth_token=#{auth_token}&api_sig=#{api_sig}"
    doc = REXML::Document.new(open(api_url).read)
    if is_error(doc)
      get_error(doc)
    else
      get_user_details(doc)
    end
  end
  
  def get_photosets(user)
    api_url = "#{@@REST_API}flickr.photosets.getList&api_key=#{@api_key}&user_id=#{user.nsid}"
    PhotosetFactory.generate_photosets(REXML::Document.new(open(api_url).read))
  end
  
  def is_error(doc)
    REXML::XPath.first(doc, "//rsp").attribute("stat").value == "fail"
  end
  
  def error(obj)
    obj.instance_of?(FlickrError)
  end
  
  def get_error(doc)
    FlickrError.new(REXML::XPath.first(doc, "//rsp").attribute("stat").value,
                    REXML::XPath.first(doc, "//rsp/err/").attribute("msg").value,
                    REXML::XPath.first(doc, "//rsp/err/").attribute("code").value)
  end
  
  def save_auth_token(auth_token)
    File.open("auth_token", "w") { |f| f << auth_token }
  end
  
  def get_saved_auth_token
    if File.exist?("auth_token")
      f = File.open("auth_token", "r")
      auth_token = f.readline
      f.close
      return auth_token
    else
      return 000
    end
  end
  
  def get_user_details(doc)
    token_node = REXML::XPath.first(doc, "//auth/token")
    perms_node = REXML::XPath.first(doc, "//auth/perms")
    user_node = REXML::XPath.first(doc, "//auth/user")
    user = FlickrUser.new(token_node.text, perms_node.text, user_node.attribute("nsid").value,
                          user_node.attribute("username").value, user_node.attribute("fullname").value)
  end
  
  def get_photos_from_set(photoset)
    api_url = "#{@@REST_API}flickr.photosets.getPhotos&api_key=#{@api_key}&photoset_id=#{photoset.id}"
    return Photofactory.generate_photos(REXML::Document.new(open(api_url).read))
  end
  
  def get_photos_not_in_set(user)
    api_sig = sig("#{@secret}api_key#{@api_key}auth_token#{user.auth_token}methodflickr.photos.getNotInSet")
    api_url = "#{@@REST_API}flickr.photos.getNotInSet&api_key=#{@api_key}&auth_token=#{user.auth_token}&api_sig=#{api_sig}"
    Photofactory.generate_photos_not_in_set(REXML::Document.new(open(api_url).read))
  end
  
  def add_photo_sizes(photo)
    api_url = "#{@@REST_API}flickr.photos.getSizes&api_key=#{@api_key}&photo_id=#{photo.id}"
    return Photofactory.add_sizes_to_photo(photo, REXML::Document.new(open(api_url).read))
  end
  
  def testsize(id)
    api_url = "#{@@REST_API}flickr.photos.getSizes&api_key=#{@api_key}&photo_id=#{id}"
    puts REXML::Document.new(open(api_url).read)
  end
  
  def sig(string)
    Digest::MD5.hexdigest(string)
  end
end