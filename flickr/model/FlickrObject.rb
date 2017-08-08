require 'date'

class FlickrObject
  def human_date(date)
    DateTime.strptime(date, '%s').strftime("%d/%m/%Y %H:%M:%S")
  end
end