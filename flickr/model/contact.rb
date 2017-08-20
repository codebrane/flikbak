class Contact < FlickrObject
  attr_accessor :nsid, :username, :realname, :friend, :family, :path_alias, :location

  def to_json(*args)
  {
    'nsid' => @nsid,
    'username' => @username,
    'realName' => @realname,
    'friend' => @friend,
    'family' => @family,
    'pathAlias' => @path_alias,
    'location' => @location,
  }.to_json(*args)
  end
end