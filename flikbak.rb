#
# FlikBak
# Flickr backup utility
# Alistair Young alistair@codebrane.com
#

require 'flickr'
require 'downloader'
require 'utils'

if ARGV.length != 2
  puts "flikback usage:"
  puts "ruby flikbak.rb BACKUP_DIR PHOTO_TYPE"
  puts "PHOTO_TYPE can be: square,thumbnail,small,medium,original"
  exit
end

backup_dir = ARGV[0]
backup_photo_type = ARGV[1]

if backup_photo_type != "square" and backup_photo_type != "thumbnail" and
   backup_photo_type != "small" and backup_photo_type != "medium" and
   backup_photo_type != "original"
  puts "I don't recognise the PHOTO_TYPE : #{backup_photo_type}"
  exit
end

flickr = Flickr.new("39ca2ef917ca17a729af14ae64d0ab6c", "52ef83f7bc249a9c")

# Check to see if the saved token is still valid
user = flickr.get_user(flickr.get_saved_auth_token)

# If not, authorise again
if flickr.error(user)
  # Get a frob...
  frob = flickr.get_frob
  # ...open the browser to let the user authorise the application...
  puts "You need to authorise FlikBak to access your photos. When you have done this, close the browser and come back here."
  puts "Press any key to launch the browser and authorise FlikBak..."
  STDIN.gets
  flickr.user_authorise(Flickr::PERM_READ, frob)
  # ...wait for them to come back here...
  puts "Thanks for authorising FlikBak! press any key to start backing up your photos..."
  STDIN.gets
  # ...get the new auth token...
  user = flickr.get_token(frob)
  # ...and save it
  flickr.save_auth_token(user.auth_token)
end

puts "Hi #{user.fullname}!"
puts "backing up your photos to #{backup_dir}"

photos_not_in_set = flickr.get_photos_not_in_set(user)

photo_sets = flickr.get_photosets(user)

# Prepare the backup directory
if !File.exists?(backup_dir)
  Dir.mkdir backup_dir
end

puts "backing up #{photos_not_in_set.length} photos not in sets"
puts "=============================================================="
photos_not_in_set.each do |photo|
  flickr.add_photo_sizes(photo)
  photo.sizes.each do |size|
    if size.type == backup_photo_type
      photo_name = Utils.sanitise(photo.title) + Utils.get_file_ext(size.source)
      photo_file = "#{backup_dir}/#{photo_name}"
      puts "#{photo.title}"
      puts "#{photo_file}"
      Downloader.download_image(size.source, photo_file)
    end
  end
end

photo_sets.each do |photo_set|
  puts
  puts "Set : #{photo_set.title}"
  puts "=============================================================="
  puts
  photos = flickr.get_photos_from_set(photo_set)
  photos.each do |photo|
    flickr.add_photo_sizes(photo)
    photo.sizes.each do |size|
      if size.type == backup_photo_type
        photoset_dir = "#{backup_dir}/" + Utils.sanitise(photo_set.title)
        photo_name = Utils.sanitise(photo.title) + Utils.get_file_ext(size.source)
        photo_file = "#{photoset_dir}/#{photo_name}"
        
        if !File.exists?(photoset_dir)
          Dir.mkdir photoset_dir
        end
        
        puts "#{photo.title}"
        puts "#{photo_file}"
        Downloader.download_image(size.source, photo_file)
      end
    end
  end
end
