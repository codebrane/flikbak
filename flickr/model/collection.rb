class Collection < FlickrObject
  attr_accessor :id, :title, :description, :sets
  
  def initialize
    @sets = []
  end
end