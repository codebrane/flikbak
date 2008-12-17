require 'open-uri'

class Downloader
  def Downloader.download_image(source, dest)
    fd = File.new(dest, "w")
    fd.write(open(source).read)
    fd.close
  end
end