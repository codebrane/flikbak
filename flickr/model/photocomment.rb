require 'json'

class PhotoComment < FlickrObject
  attr_accessor :date_created, :author, :author_url, :text, :user_profile
  
  def initialize
    @type = 'comment'
  end
  
  def to_json(*args)
  {
    'type' => @type,
    'dateCreated' => human_date(@date_created),
    'author' => @author,
    'authorUrl' => @author_url,
    'text' => @text,
    'userProfile' => @user_profile.to_json
  }.to_json(*args)
  end
end