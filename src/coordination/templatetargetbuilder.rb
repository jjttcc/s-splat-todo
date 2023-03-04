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

#!!!!remove asap:
  def obsolete_perhaps__prepare_targets
    self.targets = []
    t = target_for(spec)
$log.warn "[TTB::prepare_targets] spec.class: #{spec.class}"
$log.warn "[TTB::prepare_targets] spec: #{spec}"
$log.warn "[TTB::prepare_targets] t: #{t.class}"
    if t != nil then
$log.warn "[TTB::prepare_targets] t: #{t.handle}"
      self.targets << t
    end
  end

  def specs
    [self.spec]
  end

  private

  attr_accessor :spec

  # Initialize with 'options', 'the_existing_targets'.
  # Set processing_mode to EDIT_MODE.
  def initialize options, the_existing_targets = nil
    self.existing_targets = the_existing_targets
    self.spec = StubbedSpec.new options
    super nil
    # (override creation-mode setting in parent:)
#!!!![to-do: check if this is the right mode]:
    self.processing_mode = EDIT_MODE
  end

end
