require 'date'

class FlickrObject
  def human_date(date)
    DateTime.strptime(date, '%s').strftime("%d/%m/%Y %H:%M:%S") unless date.nil?
  end
  
  def human_date_from_string(date_string)
    DateTime.parse(date_string).strftime("%d/%m/%Y %H:%M:%S") unless date_string.nil?
  end
end