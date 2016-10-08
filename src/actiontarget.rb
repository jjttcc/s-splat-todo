# Targets of one or more actions to be executed by the system
module ActionTarget
  attr_reader :title, :content, :handle, :media, :priority, :comment
  alias :description :content
  alias :name :handle
  alias :detail :comment

  private
  attr_reader :foo

  protected

  attr_reader :manager

  def initialize spec
    set_fields spec
    check_fields
    @manager.register self
@foo = "foo" #!!!!!!!!!!!!!!!!
  end

  def set_fields spec
    @title = spec.title
    @handle = spec.handle
    @media = spec.media
    @content = spec.content
    @manager = spec.action_manager
  end

  def check_fields
    # handle serves as an id and is mandatory.
    if not self.handle then $log.warn "No handle for #{self.title}" end
    if not self.manager then $log.warn "No action manager for #{self.title}" end
  end
end
