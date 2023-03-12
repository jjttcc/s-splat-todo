require 'targetbuilder'
require 'stubbedspec'

# Builder of "template" s*todo target objects
class TemplateTargetBuilder < TargetBuilder

  public

  # Set 'processing_mode' to 'm'.
  pre ' m is edit or create' do |m| m == EDIT_MODE || m == CREATE_MODE end
  post 'mode set to "m"' do |res, m| self.processing_mode == m end
  def set_processing_mode(m)
    self.processing_mode = m
  end

  def specs
    [self.spec]
  end

  protected

  attr_accessor :spec

  private

  # Initialize with 'options', 'the_existing_targets'.
  # Set processing_mode to EDIT_MODE.
  def initialize(options, the_existing_targets = nil, the_spec = nil)
    self.existing_targets = the_existing_targets
    if the_spec.nil? then
    # (Initialize self.spec with defaults [2nd arg]:)
      self.spec = StubbedSpec.new(options, true)
    else
      self.spec = the_spec
    end
    super nil
    # (override creation-mode setting in parent:)
    self.processing_mode = EDIT_MODE
  end

end
