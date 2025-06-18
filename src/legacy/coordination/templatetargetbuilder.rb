require 'targetbuilder'
require 'stubbedspec'

# Builder that takes one 'spec' and uses it to build (or modify) one
# STodoTarget object.
class TemplateTargetBuilder < TargetBuilder

  public

  def specs
    [self.spec]
  end

  def spec_collector=(sc)
    super(sc)
    self.spec = StubbedSpec.new(sc, true)
  end

  protected

  attr_accessor :spec

  private

  # Initialize with 'options', 'the_existing_targets'.
  # Set processing_mode to EDIT_MODE.
  post 'spec exists' do ! self.spec.nil? end
  #post 'spec set as ordered' do |result, opts, extgts, the_spec|
  #  implies(! the_spec.nil?, self.spec == the_spec)
  #end
  #post 'existing_targets set' do |res, opts, the_existing_targets|
  #  implies(! the_existing_targets.nil?,
  #          self.existing_targets == the_existing_targets)
  #end
  def initialize(options, the_existing_targets = nil, the_spec = nil,
                config)
    self.existing_targets = the_existing_targets
    if the_spec.nil? then
      # (2nd arg: Initialize self.spec with defaults:)
      self.spec = StubbedSpec.new(options, true)
    else
      self.spec = the_spec
    end
    super options, config
    # (override creation-mode setting in parent:)
    self.processing_mode = EDIT_MODE
  end

end
