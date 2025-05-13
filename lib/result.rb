class Result
  attr_reader :value, :error

  def initialize(success, value = nil, error = nil)
    @success = success
    @value = value
    @error = error
  end

  def self.success(value = nil)
    new(true, value, nil)
  end

  def self.error(error_messasge)
    new(false, nil, error_messasge)
  end

  def success?
    @success
  end 

  def error?
    !@success
  end
  
end