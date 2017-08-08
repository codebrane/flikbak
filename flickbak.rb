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

photosets = flickr.get_photosets
photosets.each do |photoset|
  p photoset.title
  photos = flickr.get_photos_in_photoset(user.id, photoset.id)
  photos.each do |photo|
    original_photo_url = "https://farm#{photo.farm}.staticflickr.com/#{photo.server}/#{photo.id}_#{photo.originalsecret}_o.#{photo.originalformat}"
    photo.original_url = original_photo_url
    photo_dir = "#{photos_dir}/#{photo.title.downcase.gsub(/[\s,]/, "_")}"
    Dir.mkdir(photo_dir) unless File.exists?(photo_dir)
    photo_filename = "#{photo_dir}/photo.#{photo.originalformat}"
    # p "downloading #{photo.title}"
    # flickr.download_photo(original_photo_url, photo_filename)
    p "creating metadata file for #{photo.title}"
    flickr.create_photo_metadata_files(photo, photo_dir)
  end
  exit
end
