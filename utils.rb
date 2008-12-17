class Utils
  def Utils.sanitise(dir)
    dir.gsub(" ", "_").gsub("/", "-").gsub(",", "_")
  end
  
  def Utils.get_file_ext(source)
    ".jpg"
  end
end