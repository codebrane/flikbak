require './flickr/flickr'
require './config'

include Config

if ARGV.length != 1
  puts 'usage: ruby flickbak.rb backupdir'
  puts 'e.g. ruby flickbak.rb photos'
  Process.exit
end

photos_dir = ARGV[0]
Dir.mkdir(photos_dir) unless File.exists?(photos_dir)

flickr = Flickr.new(API_KEY, SECRET, './tokens')

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
    original_photo_url = "https://farm#{photo.farm}.staticflickr.com/#{photo.server}/#{photo.id}_#{photo.originalsecret}_o.#{photo.originalformat}"
    photo.original_url = original_photo_url
    photo_dir = "#{photoset_dir}/#{photo.title.downcase.gsub(/[\s,&]/, "_")}"
    Dir.mkdir(photo_dir) unless File.exists?(photo_dir)
    photo_filename = "#{photo_dir}/#{photo.title.gsub(/[\s,]/, "_")}.#{photo.originalformat}"
    flickr.download_photo(original_photo_url, photo_filename)
    flickr.create_metadata_file(photo, photo_dir, "#{photo.title.gsub(/[\s,]/, "_")}.json")
  end
  flickr.create_metadata_file(photoset, photoset_dir, "#{photoset.title.gsub(/[\s,\/]/, "_")}.json")
  # exit
end
