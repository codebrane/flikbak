class PhotoSet < FlickrObject
  attr_accessor :id, :primary, :secret, :server, :farm, :photos, :videos,
                :title, :description, :count_views, :count_comments,
                :date_create, :date_update, :ownername
                
  def to_json(*args)
  {
    'id' => @id,
    'primary' => @primary,
    'secret' => @secret,
    'farm' => @farm,
    'title' => @title,
    'description' => @description,
    'noOfViews' => @count_views,
    'noOfComments' => @count_comments,
    'ownername' => @ownername,
    'dateCreated' => human_date(@date_create),
#    'dateUpdated' => (@date_update == "0") ? nil : human_date(@date_update),
    'dateUpdated' => human_date(@date_update)
  }.to_json(*args)
  end
end