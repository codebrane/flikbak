class PhotoSet < FlickrObject
  attr_accessor :id, :primary, :secret, :server, :farm, :photos, :videos,
                :title, :description, :count_views, :count_comments,
                :date_create, :date_update
end