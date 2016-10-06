require_relative 'actiontarget'

# Notes/memoranda to be recorded, for the purpose of aiding memory and/or
# items to be reminded of at a future date.
class Memorandum
  include ActionTarget

  def initialize spec
    super spec
  end
end
