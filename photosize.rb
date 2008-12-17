class PhotoSize
  attr_reader :label, :url, :media, :height, :source, :width, :type
  attr_accessor :candownload, :canblog, :canprint
  
  def initialize(label, url, media, height, source, width, type)
    @label = label
    @url = url
    @media = media
    @height = height
    @source = source
    @width = width
    @type = type
  end
end