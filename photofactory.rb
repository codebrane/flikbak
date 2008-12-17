require 'photo'
require 'photosize'

class Photofactory
  def Photofactory.generate_photos(doc)
    photos = Array.new
    
    REXML::XPath.each(doc, "//rsp/photoset/photo") do |photo|
      photos[photos.length] = Photo.new(photo.attribute("farm").value,
                                        photo.attribute("title").value,
                                        photo.attribute("isprimary").value,
                                        photo.attribute("id").value,
                                        photo.attribute("server").value,
                                        photo.attribute("secret").value)
    end
    
    return photos
  end
  
  def Photofactory.generate_photos_not_in_set(doc)
    photos = Array.new
    
    REXML::XPath.each(doc, "//rsp/photos/photo") do |photo|
      photos[photos.length] = Photo.new(photo.attribute("farm").value,
                                        photo.attribute("title").value,
                                        photo.attribute("ispublic").value,
                                        photo.attribute("id").value,
                                        photo.attribute("server").value,
                                        photo.attribute("secret").value)
    end
    
    return photos
  end
  
  def Photofactory.add_sizes_to_photo(photo, doc)
    sizes_node = REXML::XPath.first(doc, "//rsp/sizes")
    
    REXML::XPath.each(sizes_node, "size") do |size|
      photo_size = PhotoSize.new(size.attribute("label").value,
                                 size.attribute("url").value,
                                 size.attribute("media").value,
                                 size.attribute("height").value,
                                 size.attribute("source").value,
                                 size.attribute("width").value,
                                 size.attribute("label").value.downcase)
                                 
      photo_size.candownload = sizes_node.attribute("candownload").value
      photo_size.canblog = sizes_node.attribute("canblog").value
      photo_size.canprint = sizes_node.attribute("canprint").value
      
      photo.add_size(photo_size)
    end
  end
end