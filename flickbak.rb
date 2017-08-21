require_relative 'flickr/flickr'

if ARGV.length != 5
  p 'usage: ruby flickbak.rb apikey secret tokensdir backupdir mode'
  p 'mode can be one of:'
  p 'sets notinset collections'
  p 'e.g. ruby flickbak.rb APIKEY SECRET tokens photos sets'
  Process.exit
end

if ((ARGV[4].downcase != 'sets') &&
    (ARGV[4].downcase != 'notinset') &&
    (ARGV[4].downcase != 'collections'))
  p "#{ARGV[4]}? I don't know how to do that!"
  Process.exit
end
mode = ARGV[4].downcase

photos_dir = ARGV[3]
Dir.mkdir(photos_dir) unless File.exists?(photos_dir)

tokensdir = ARGV[2]
flickr = Flickr.new(ARGV[0], ARGV[1], tokensdir)

unless File.exist?("#{tokensdir}/access_token") && File.exist?("#{tokensdir}/oauth_token_secret")
  flickr.get_access_token
end

user = flickr.login

p "Creating your contacts and groups #{user.username}"

flickr.create_metadata_file(flickr.get_contacts, "#{photos_dir}/contacts.json")
p "created in #{photos_dir}/contacts.json"
flickr.create_metadata_file(flickr.get_groups(user.id), "#{photos_dir}/groups.json")
p "created in #{photos_dir}/groups.json"

if (mode == 'collections')
  p "Looking for your collections"
  
  collections_dir = "#{photos_dir}/collections"
  Dir.mkdir(collections_dir) unless File.exists?(collections_dir)
  
  collections = flickr.get_collections(user.id)
  collections.each do |collection|
    p "#{collection.title} -> #{collection.sets.count}"
    
    collection_title_for_disk = "#{collection.title.downcase.gsub(/[\s,\/&.']/, "_")}-#{collection.id}"
    collection_dir = "#{collections_dir}/#{collection_title_for_disk}"
    Dir.mkdir(collection_dir) unless File.exists?(collection_dir)
    
    if (collection.sets.count > 0)
      photosets_count = 0
      collection.sets.each do |photoset|
        photosets_count += 1
        p "Photoset #{photosets_count}/#{collection.sets.count} #{photoset.title}"
        photoset_dir = "#{collection_dir}/#{photoset.title.gsub(/[\s,\/&.]/, "_")}"
        Dir.mkdir(photoset_dir) unless File.exists?(photoset_dir)
        photos = flickr.get_photos_in_photoset(user.id, photoset)
        photos_count = 0
        photos.each do |photo|
          photos_count += 1
          p "Photo #{photos_count}/#{photos.count} #{photo.title}"
          photo.original_url = flickr.get_original_photo_url(photo)
          photo_title_for_disk = "#{photo.title.downcase.gsub(/[\s,\/&]/, "_")}-#{photo.id}"
          photo_dir = "#{photoset_dir}/#{photo_title_for_disk}"
          Dir.mkdir(photo_dir) unless File.exists?(photo_dir)
          flickr.download_photo(photo.original_url, "#{photo_dir}/#{photo_title_for_disk}.#{photo.originalformat}")
          flickr.create_metadata_file(photo, "#{photo_dir}/#{photo_title_for_disk}.json")
        end
        flickr.create_metadata_file(photoset, "#{photoset_dir}/#{photoset.title.gsub(/[\s,\/]/, "_")}.json")
      end
    end
  end
  exit
end

if (mode == 'notinset')
  p "Looking for your photos not in a set"
  photos_not_in_sets = flickr.get_photos_not_in_sets
  photos_count = 0
  photos_not_in_sets.each do |photo|
    photos_count += 1
    p "Photo not in set #{photos_count}/#{photos_not_in_sets.count} #{photo.title}"
    photo.original_url = flickr.get_original_photo_url(photo)
    photo_title_for_disk = "#{photo.title.downcase.gsub(/[\s,\/&]/, "_")}-#{photo.id}"
    not_in_set_dir = "#{photos_dir}/not_in_set"
    Dir.mkdir(not_in_set_dir) unless File.exists?(not_in_set_dir)
    photo_dir = "#{not_in_set_dir}/#{photo_title_for_disk}"
    Dir.mkdir(photo_dir) unless File.exists?(photo_dir)
    flickr.download_photo(photo.original_url, "#{photo_dir}/#{photo_title_for_disk}.#{photo.originalformat}")
    flickr.create_metadata_file(photo, "#{photo_dir}/#{photo_title_for_disk}.json")
  end
end

if (mode == 'sets')
  p "Looking for your photosets"
  photosets = flickr.get_photosets(user.id)
  photosets_count = 0
  photosets.each do |photoset|
    photosets_count += 1
    p "Photoset #{photosets_count}/#{photosets.count} #{photoset.title}"
    photoset_dir = "#{photos_dir}/#{photoset.title.gsub(/[\s,\/&]/, "_")}"
    Dir.mkdir(photoset_dir) unless File.exists?(photoset_dir)
    photos = flickr.get_photos_in_photoset(user.id, photoset)
    photos_count = 0
    photos.each do |photo|
      photos_count += 1
      p "Photo #{photos_count}/#{photos.count} #{photo.title}"
      photo.original_url = flickr.get_original_photo_url(photo)
      photo_title_for_disk = "#{photo.title.downcase.gsub(/[\s,\/&]/, "_")}-#{photo.id}"
      photo_dir = "#{photoset_dir}/#{photo_title_for_disk}"
      Dir.mkdir(photo_dir) unless File.exists?(photo_dir)
      flickr.download_photo(photo.original_url, "#{photo_dir}/#{photo_title_for_disk}.#{photo.originalformat}")
      flickr.create_metadata_file(photo, "#{photo_dir}/#{photo_title_for_disk}.json")
    end
    flickr.create_metadata_file(photoset, "#{photoset_dir}/#{photoset.title.gsub(/[\s,\/]/, "_")}.json")
  end
end
