# Targets of some action to be executed by the system
module ActionTarget
  attr_reader :title, :content
  alias :description :content

  def initialize spec
    @title = spec.title
    @content = spec.content
  end
end
