require_relative 'flickr/flickr'
require 'logger'

MAX_DOWNLOAD_TRIES = 10
LOG_DATETIME_FORMAT = "%Y-%m-%d %H:%M:%S"

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

log_dir = "#{photos_dir}/logs"
Dir.mkdir(log_dir) unless File.exists?(log_dir)

p "Creating your contacts and groups #{user.username}"
user_dir = "#{photos_dir}/user"
Dir.mkdir(user_dir) unless File.exists?(user_dir)
flickr.create_metadata_file(flickr.get_contacts, "#{user_dir}/contacts.json")
flickr.create_metadata_file(flickr.get_groups(user.id), "#{user_dir}/groups.json")

title_tidy = "[\s,\/&.']"

if (mode == 'collections')
  p "Looking for your collections"
  
  log = Logger.new("#{log_dir}/collections.log")
  log.formatter = proc do |severity, datetime, progname, msg|
    date_format = datetime.strftime(LOG_DATETIME_FORMAT)
    "[#{date_format}] #{severity} #{msg}\n"
  end  
  
  collections_dir = "#{photos_dir}/collections"
  Dir.mkdir(collections_dir) unless File.exists?(collections_dir)
  
  collections = flickr.get_collections(user.id)
  collections.each do |collection|
    p "#{collection.title} -> #{collection.sets.count}"
    
    collection_title_for_disk = "#{collection.title.downcase.gsub(/#{title_tidy}/, "_")}-#{collection.id}"
    collection_dir = "#{collections_dir}/#{collection_title_for_disk}"
    Dir.mkdir(collection_dir) unless File.exists?(collection_dir)
    
    if (collection.sets.count > 0)
      photosets_count = 0
      collection.sets.each do |photoset|
        photosets_count += 1
        p "Photoset #{photosets_count}/#{collection.sets.count} #{photoset.title}"
        photoset_dir = "#{collection_dir}/#{photoset.title.gsub(/#{title_tidy}/, "_")}"
        Dir.mkdir(photoset_dir) unless File.exists?(photoset_dir)
        photos = flickr.get_photos_in_photoset(user.id, photoset)
        photos_count = 0
        photos.each do |photo|
          photos_count += 1
          p "Photo #{photos_count}/#{photos.count} #{photo.title}"
          photo.original_url = flickr.get_original_photo_url(photo)
          photo_title_for_disk = "#{photo.title.downcase.gsub(/#{title_tidy}/, "_")}-#{photo.id}"
          photo_dir = "#{photoset_dir}/#{photo_title_for_disk}"
          Dir.mkdir(photo_dir) unless File.exists?(photo_dir)
          downloaded = flickr.download_photo(photo.original_url,
            "#{photo_dir}/#{photo_title_for_disk}.#{photo.originalformat}",
            MAX_DOWNLOAD_TRIES)
          if (!downloaded)
            p "could not download #{photo.original_url} to #{photo_dir}/#{photo_title_for_disk}.#{photo.originalformat}"
          end
          flickr.create_metadata_file(photo, "#{photo_dir}/#{photo_title_for_disk}.json")
          log.info("#{collection.title}|#{photoset.title}|#{photo.title}|#{photo.id}|#{photo_dir}/#{photo_title_for_disk}.#{photo.originalformat}")
        end
        flickr.create_metadata_file(photoset, "#{photoset_dir}/#{photoset.title.gsub(/#{title_tidy}/, "_")}.json")
      end
    end
  end
  exit
end

if (mode == 'notinset')
  p "Looking for your photos not in a set"
  
  log = Logger.new("#{log_dir}/notinset.log")
  log.formatter = proc do |severity, datetime, progname, msg|
    date_format = datetime.strftime(LOG_DATETIME_FORMAT)
    "[#{date_format}] #{severity} #{msg}\n"
  end  
  
  photos_not_in_sets = flickr.get_photos_not_in_sets
  photos_count = 0
  photos_not_in_sets.each do |photo|
    photos_count += 1
    p "Photo not in set #{photos_count}/#{photos_not_in_sets.count} #{photo.title}"
    photo.original_url = flickr.get_original_photo_url(photo)
    photo_title_for_disk = "#{photo.title.downcase.gsub(/#{title_tidy}/, "_")}-#{photo.id}"
    not_in_set_dir = "#{photos_dir}/not_in_set"
    Dir.mkdir(not_in_set_dir) unless File.exists?(not_in_set_dir)
    photo_dir = "#{not_in_set_dir}/#{photo_title_for_disk}"
    Dir.mkdir(photo_dir) unless File.exists?(photo_dir)
    downloaded = flickr.download_photo(photo.original_url,
      "#{photo_dir}/#{photo_title_for_disk}.#{photo.originalformat}",
      MAX_DOWNLOAD_TRIES)
    if (!downloaded)
      p "could not download #{photo.original_url} to #{photo_dir}/#{photo_title_for_disk}.#{photo.originalformat}"
    end
    flickr.create_metadata_file(photo, "#{photo_dir}/#{photo_title_for_disk}.json")
    log.info("#{photo.title}|#{photo.id}|#{photo_dir}/#{photo_title_for_disk}.#{photo.originalformat}")
  end
end

if (mode == 'sets')
  p "Looking for your photosets"
  
  photosets_dir = "#{photos_dir}/sets"
  Dir.mkdir(photosets_dir) unless File.exists?(photosets_dir)
  
  log = Logger.new("#{log_dir}/sets.log")
  log.formatter = proc do |severity, datetime, progname, msg|
    date_format = datetime.strftime(LOG_DATETIME_FORMAT)
    "[#{date_format}] #{severity} #{msg}\n"
  end  
  
  photosets = flickr.get_photosets(user.id)
  photosets_count = 0
  photosets.each do |photoset|
    photosets_count += 1
    p "Photoset #{photosets_count}/#{photosets.count} #{photoset.title}"
    photoset_dir = "#{photosets_dir}/#{photoset.title.gsub(/#{title_tidy}/, "_")}"
    Dir.mkdir(photoset_dir) unless File.exists?(photoset_dir)
    photos = flickr.get_photos_in_photoset(user.id, photoset)
    photos_count = 0
    photos.each do |photo|
      photos_count += 1
      p "Photo #{photos_count}/#{photos.count} #{photo.title}"
      photo.original_url = flickr.get_original_photo_url(photo)
      photo_title_for_disk = "#{photo.title.downcase.gsub(/#{title_tidy}/, "_")}-#{photo.id}"
      photo_dir = "#{photoset_dir}/#{photo_title_for_disk}"
      Dir.mkdir(photo_dir) unless File.exists?(photo_dir)
      downloaded = flickr.download_photo(photo.original_url,
        "#{photo_dir}/#{photo_title_for_disk}.#{photo.originalformat}",
        MAX_DOWNLOAD_TRIES)
      if (!downloaded)
        p "could not download #{photo.original_url} to #{photo_dir}/#{photo_title_for_disk}.#{photo.originalformat}"
      end
      flickr.create_metadata_file(photo, "#{photo_dir}/#{photo_title_for_disk}.json")
      log.info("#{photoset.title}|#{photo.title}|#{photo.id}|#{photo_dir}/#{photo_title_for_disk}.#{photo.originalformat}")
    end
    flickr.create_metadata_file(photoset, "#{photoset_dir}/#{photoset.title.gsub(/#{title_tidy}/, "_")}.json")
  end
end
