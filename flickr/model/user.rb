class User
  attr_accessor :id, :username, :path_alias
  
  def initialize(id, username, path_alias)
    @type = 'user'
    @id = id
    @username = username
    @path_alias = path_alias
  end
end