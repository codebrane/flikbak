class FlickrUser
  attr_reader :auth_token, :perms, :nsid, :username, :fullname
  
  def initialize(auth_token, perms, nsid, username, fullname)
    @auth_token = auth_token
    @perms = perms
    @nsid = nsid
    @username = username
    @fullname = fullname
  end
end