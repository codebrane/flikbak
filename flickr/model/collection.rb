class Collection < FlickrObject
  attr_accessor :id, :title, :description, :sets
  
  def initialize
    @type = 'collection'
    @sets = []
  end
end