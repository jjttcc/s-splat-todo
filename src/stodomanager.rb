require_relative 'mailer'
require_relative 'calendarentry'
require_relative 'preconditionerror'

# Basic manager of s*todo actions
class STodoManager
  attr_reader :new_targets, :existing_targets, :mailer, :calendar

  public

  # Call `initiate' on each element of @new_targets.
  # precondition: new_targets != nil
  def perform_initial_processing
    if ! new_targets then raise PreconditionError, 'new_targets != nil' end
    new_targets.each do |h, t|
      t.initiate(self)
    end
    @target_builder.spec_collector.initial_cleanup new_targets
    all_targets = existing_targets.merge(new_targets)
    @data_manager.store_targets(all_targets)
  end

  # Call `initiate' on each element of @new_targets.
  # precondition: new_targets != nil
  def old____perform_initial_processing
    if ! new_targets then raise PreconditionError, 'new_targets != nil' end
    new_targets.each do |h, t|
      if not @existing_targets[t.handle] then
        t.initiate(self)
      else
#!!!        $log.warn "Handle #{t.handle} already exists - cannot process the" +
#!!!          " associated #{t.formal_type}; skipping this item."
      end
    end
    @target_builder.spec_collector.initial_cleanup self.existing_targets
    all_targets = @existing_targets.merge(@new_targets)
    @data_manager.store_targets(all_targets)
  end

  def perform_ongoing_processing
    usethese_targets = @data_manager.restored_targets
    existing_targets.values.each do |t|
      t.perform_ongoing_actions(self)
    end
  end

  private

  def initialize config, tgt_builder = nil
    @data_manager = config.data_manager
    @existing_targets = @data_manager.restored_targets
$log.debug "#{self.class} old target count: #{existing_targets.length}"
    if tgt_builder != nil then
      @new_targets = {}
      @target_builder = tgt_builder
      tgts = @target_builder.targets
      tgts.keys.each do |hndl|
        if @existing_targets[hndl] != nil then
          t = @existing_targets[hndl]
          $log.warn "Handle #{hndl} already exists - cannot process the" +
            " associated #{t.formal_type} - skipping this item."
        else
          @new_targets[hndl] = tgts[hndl]
        end
      end
$log.debug "#{self.class} new target count: #{new_targets.length}"
    end
    @mailer = Mailer.new config
    @calendar = CalendarEntry.new config
  end

end
