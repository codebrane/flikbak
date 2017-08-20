require 'json'

class Photo < FlickrObject
  attr_accessor :id, :secret, :server, :farm,
                :title, :description, :dateupload, :datetaken,
                :tags, :views, :originalsecret, :originalformat,
                :original_url, :no_of_comments, :comments
                
  def initialize
    @tags = []
    @comments = []
  end
  
  def tags=value
    @tags = value.split(" ")
  end
  
  def add_comment(comment)
    @comments.push(comment)
  end
  
  def to_json(*args)
  {
    'title' => @title,
    'description' => @description,
    'dateTaken' => human_date_from_string(@datetaken),
    'dateUploaded' => human_date(@dateupload),
    'tags' => @tags,
    'noOfComments' => @no_of_comments,
    'comments' => @comments,
    'views' => @views,
    'originalURL' => @original_url
  }.to_json(*args)
  end
end