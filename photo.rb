class Photo
  attr_reader :farm, :title, :isprimary, :id, :server, :secret, :sizes
  
  def initialize(farm, title, isprimary, id, server, secret)
    @farm = farm
    @title = title
    @isprimary = isprimary
    @id = id
    @server = server
    @secret = secret
    
    @sizes = Array.new
  end
  
  def add_size(size)
    @sizes[@sizes.length] = size
  end
  
  def dump
    puts "============================================================================="
    puts "#{@title}"
    puts "farm=#{@farm}:isprimary=#{@isprimary}:id=#{@id}:server=#{@server}:secret=#{@secret}"
    puts "============================================================================="
  end
end