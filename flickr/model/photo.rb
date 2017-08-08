require 'json'

class Photo < FlickrObject
  attr_accessor :id, :secret, :server, :farm,
                :title, :description, :dateupload, :datetaken,
                :tags, :views, :originalsecret, :originalformat,
                :original_url
                
  def initialize
    @tags = []
  end
  
  def tags=value
    @tags = value.split(" ")
  end
  
  def to_json(*args)
  {
    'title' => @title,
    'description' => @description,
    'dateTaken' => human_date(@datetaken),
    'dateUploaded' => human_date(@dateupload),
    'tags' => @tags,
    'views' => @views,
    'originalURL' => @original_url
  }.to_json(*args)
  end
end