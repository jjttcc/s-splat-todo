#require 'publisher'
require 'work_server'
require 'work_server_process'
#require 'stodo_services_constants'
#require 'command_line_request'
#require 'templatetargetbuilder'
#require 'templateoptions'

# Coordinates worker processes to carry out client requests.
#!!!!!Move this file out of request_handling.
#class WorkCoordinator < Publisher
class WorkCoordinator

  public

  def delegate_request(request_object_key)
    work_server = next_available_work_server
    self.occupied_work_servers << work_server
    work_server.notify_worker(request_object_key)
    update_available_work_servers
  end

  def remove___stash_delegate_request(request_object_key)
    request = message_broker.object(request_object_key)
    cmd = command_for[request.command]
    if ! cmd.nil? then
      cmd.execute(request)
    else
      "!!![appropriate error message]!!!"
    end
  end

  private

  def next_available_work_server
    # Return the first available server and remove it from aws:
    result = available_work_servers.shift
  end

  def update_available_work_servers
    occupied_work_servers.each do |s|
      if ! message_broker.retrieved_message(s.server_id).nil? then
        available_work_servers << s
        occupied_work_servers.delete(s)
      end
    end
  end

  private

  # Number of 'work_servers':
  SERVER_COUNT = 10
  WORK_SERVER_ID_BASE = 'work-server-'

  attr_accessor :message_broker, :child_pids
  # Array of WorkServerProcess, each representing a work server:
  attr_accessor :work_servers
  # 
  # Array of available WorkServerProcess objects:
  attr_accessor :available_work_servers
  # Array of occupied WorkServerProcess objects:
  attr_accessor :occupied_work_servers

  private

  def initialize(config)
    self.message_broker = config.app_configuration.application_message_broker
    self.work_servers = []
    self.available_work_servers = []
    self. occupied_work_servers= []
    self.child_pids = []
    (1 .. SERVER_COUNT).each do |i|
      server_id = "#{WORK_SERVER_ID_BASE}#{i}"
      ch_pid = start_server_process(server_id)
      ws = WorkServerProcess.new(server_id, ch_pid, config.app_configuration)
      self.work_servers << ws
      self.available_work_servers << ws
    end
  end

  private

  def start_server_process(server_id)
    child_pid = fork do
      ws = WorkServer.new(server_id)
      ws.execute
    end
    result = child_pid
    Process.detach(child_pid)
    result
  end

  def stash_initialize_remove(config)
    self.config = config
    app_config = config.app_configuration
    self.message_broker = app_config.application_message_broker
    initialize_pubsub_broker(app_config)
    self.manager =
      config.new_stodo_manager(service_name: Configuration.service_name,
                               debugging: true)
#    init_command_table(manager)
    # dummy:
    options = TemplateOptions.new([], true)
    target_builder = TemplateTargetBuilder.new(options,
                                     manager.existing_targets, nil, config)
    target_builder.set_processing_mode TemplateTargetBuilder::CREATE_MODE
    manager.target_builder = target_builder
    super(SERVER_RESPONSE_CHANNEL)
  end

end
