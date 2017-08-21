class UserProfile < FlickrObject
  attr_accessor :join_date, :occupation, :hometown, :showcase_set,
                :profile_description, :facebook, :twitter, :tumblr,
                :instagram, :pinterest, :id, :nsid, :realname
                
  def initialize
    @type = 'userprofile'
  end
                
  def to_json(*args)
  {
    'type' => @type,
    'id' => @id,
    'nsid' => @nsid,
    'realName' => @realname,
    'joinDate' => human_date(@join_date),
    'occupation' => @occupation,
    'hometown' => @hometown,
    'showcase_set' => @showcase_set,
    'profile_description' => @profile_description,
    'facebook' => @facebook,
    'twitter' => @twitter,
    'tumblr' => @tumblr,
    'instagram' => @instagram,
    'pinterest' => @pinterest
  }.to_json(*args)
  end
end