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
    raise PreconditionError, 'new_targets != nil' if new_targets == nil
    new_targets.each do |h, t|
      t.initiate(self)
    end
    @target_builder.spec_collector.initial_cleanup new_targets
    all_targets = existing_targets.merge(new_targets)
    @data_manager.store_targets(all_targets)
  end

  def perform_ongoing_processing
    existing_targets.values.each do |t|
      t.perform_ongoing_actions(self)
    end
  end

  private

  def initialize config, tgt_builder = nil
    @data_manager = config.data_manager
    @existing_targets = @data_manager.restored_targets
    new_duphndles = {}
$log.debug "#{self.class} old target count: #{existing_targets.length}"
    if tgt_builder != nil then
      @new_targets = {}
      @target_builder = tgt_builder
      tgts = @target_builder.targets
      tgts.each do |tgt|
        hndl = tgt.handle
        if @existing_targets[hndl] != nil then
          t = @existing_targets[hndl]
          $log.warn "Handle #{hndl} already exists - cannot process the" +
            " associated #{t.formal_type} - skipping this item."
        else
          if @new_targets[hndl] != nil then
            new_duphndles[hndl] = true
            report_new_conflict @new_targets[hndl], tgt
          else
            @new_targets[hndl] = tgt
          end
        end
      end
$log.debug "#{self.class} new target count: #{new_targets.length}"
    end
    # Remove any remaining new targets with a conflicting/duplicate handle.
    new_duphndles.keys.each {|h| @new_targets.delete(h) }
    @mailer = Mailer.new config
    @calendar = CalendarEntry.new config
  end

  def report_new_conflict target1, target2
    msg = "The same handle, #{target1.handle}, was found in 2 or more new " +
      "items: item1: #{target1.title}/#{target1.formal_type}, item2: " +
      "#{target2.title}/#{target2.formal_type}"
    $log.warn msg
  end

end
