require 'photoset'

class PhotosetFactory
  # <rsp stat='ok'>
  # <photosets>
  #	 <photoset farm='4' photos='31' primary='3086410179' videos='1' id='72157610808653040' server='3213' secret='d470922995'>
  #		 <title>Maol Chinn Dearg, 6/12/08</title>
  #		 <description>Maol Chinn Dearg on the South Glen Shiel ridge</description>
  #	 </photoset>
  # </photosets>
  
  def PhotosetFactory.generate_photosets(doc)
    photo_sets = Array.new
    
    REXML::XPath.each(doc, "//rsp/photosets/photoset") do |photoset|
      title = REXML::XPath.first(photoset, "title")
      description = REXML::XPath.first(photoset, "description")
      
      photo_sets[photo_sets.length] = Photoset.new(photoset.attribute("farm").value,
                                                   photoset.attribute("photos").value,
                                                   photoset.attribute("primary").value,
                                                   photoset.attribute("videos").value,
                                                   photoset.attribute("id").value,
                                                   photoset.attribute("server").value,
                                                   photoset.attribute("secret").value,
                                                   title.text,
                                                   description.text)
    end
    
    return photo_sets
  end
end
