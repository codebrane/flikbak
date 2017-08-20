require './flickr/flickr'

if ARGV.length != 4
  puts 'usage: ruby flickbak.rb apikey secret tokensdir backupdir'
  puts 'e.g. ruby flickbak.rb APIKEY SECRET tokens photos'
  Process.exit
end

photos_dir = ARGV[3]
Dir.mkdir(photos_dir) unless File.exists?(photos_dir)

flickr = Flickr.new(ARGV[0], ARGV[1], ARGV[2])

unless File.exist?("tokens/access_token") && File.exist?("tokens/oauth_token_secret")
  flickr.get_access_token
end

user = flickr.login

flickr.create_metadata_file(flickr.get_contacts, photos_dir, "contacts.json")
flickr.create_metadata_file(flickr.get_groups(user.id), photos_dir, "groups.json")

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
    photo_title_for_disk = photo.title.downcase.gsub(/[\s,&]/, "_")
    photo_dir = "#{photoset_dir}/#{photo_title_for_disk}"
    Dir.mkdir(photo_dir) unless File.exists?(photo_dir)
    flickr.download_photo(photo.original_url, "#{photo_dir}/#{photo_title_for_disk}.#{photo.originalformat}")
    flickr.create_metadata_file(photo, photo_dir, "#{photo_title_for_disk}.json")
  end
  flickr.create_metadata_file(photoset, photoset_dir, "#{photoset.title.gsub(/[\s,\/]/, "_")}.json")
end
