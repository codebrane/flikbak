class Photoset
  attr_reader :farm, :photos, :primary, :videos, :id, :server, :secret, :title, :description
  
  def initialize(farm, photos, primary, videos, id, server, secret, title, description)
    @farm = farm
    @photos = photos
    @primary = primary
    @videos = videos
    @id = id
    @server = server
    @secret = secret
    @title = title
    @description = description
  end
  
  def dump
    puts "============================================================================="
    puts "#{@title}"
    puts "#{@description}"
    puts "farm=#{@farm}:photos=#{@photos}:primary=#{@primary}:videos=#{@videos}:id=#{@id}:server=#{@server}:secret=#{@secret}"
    puts "============================================================================="
  end
end