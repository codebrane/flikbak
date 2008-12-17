class FlickrError
#  <rsp stat='fail'>
#  	<err msg='Invalid auth token' code='98'/>
#  </rsp>
  
  attr_reader :stat, :message, :code
  
  def initialize(stat, message, code)
    @stat = stat
    @message = message
    @code = code
  end
end