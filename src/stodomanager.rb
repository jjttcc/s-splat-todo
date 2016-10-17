require_relative 'mailer'
require_relative 'calendarentry'

# Basic manager of s*todo actions
class STodoManager
  attr_reader :targets, :mailer, :calendar, :item_for_handle

  public

  # Call `initiate' on each element of @targets.
  def perform_initial_processing
    old_handles = @data_manager.stored_handles
    targets.each do |t|
      if not old_handles[t.handle] then
        t.initiate(self)
        @item_for_handle[t.handle] = t
      else
        $log.warn "Handle #{t.handle} already exists - cannot process the" +
          " associated #{t.formal_type}; skipping this item."
      end
    end
    @target_builder.spec_collector.initial_cleanup @item_for_handle
$log.debug "================== item_for_handle report =================="
item_for_handle.each do |k, s|
$log.debug "handle: '#{k}', item[title/type]: <<<#{s.title}, #{s.formal_type}>>>"
end
    @data_manager.add_handles(item_for_handle.keys)
  end

  # Call `initiate' on each element of @targets.
  def perform_notifications
    targets.each do |t|
      t.perform_ongoing_actions(self)
    end
  end

  private

  def initialize tgtbuilder, config
    @target_builder = tgtbuilder
    @targets = @target_builder.targets
    @config = config
    @data_manager = config.data_manager
    @specs = tgtbuilder.specs
    @mailer = Mailer.new @config
    @calendar = CalendarEntry.new @config
    @item_for_handle = {}
$log.debug "Here's the calendar - what does it look like?: #{@calendar.inspect}"
  end

end
