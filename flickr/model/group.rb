class Group < FlickrObject
  attr_accessor :nsid, :name, :is_moderator, :is_admin
  
  def initialize
    @type = 'group'
  end
  
  def to_json(*args)
  {
    'type' => @type,
    'nsid' => @nsid,
    'name' => @name,
    'isModerator' => @is_moderator,
    'isAdmin' => @is_admin
  }.to_json(*args)
  end
end