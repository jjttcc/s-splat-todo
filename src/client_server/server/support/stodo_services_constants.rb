# Constants relevant to TAT services
module STodoServicesConstants
  public

  SERVER_REQUEST_CHANNEL         = 'requests-to-stodo-server'
  SERVER_RESPONSE_CHANNEL        = 'responses-from-stodo-server'
  CLI_CLIENT_REQUEST_CHANNEL     = 'cli-client-requests'
  CLI_CLIENT_RESPONSE_CHANNEL    = 'cli-client-responses'

=begin
# Is this of any use for ideas?:
  EXMON_PAUSE_SECONDS, EXMON_LONG_PAUSE_ITERATIONS = 3, 35
  RUN_STATE_EXPIRATION_SECONDS, DEFAULT_EXPIRATION_SECONDS,
    DEFAULT_ADMIN_EXPIRATION_SECONDS, DEFAULT_APP_EXPIRATION_SECONDS =
      15, 28800, 600, 120
  # Number of seconds of "margin" to give the exchange monitor before the
  # next closing time in order to avoid interfering with its operation:
  PRE_CLOSE_TIME_MARGIN = 300
  # Number of seconds of "margin" to give the exchange monitor after the
  # next closing time in order to avoid interfering with its operation:
  POST_CLOSE_TIME_MARGIN = 90
  # Default number of seconds to wait for a message acknowledgement before
  # giving up:
  MSG_ACK_TIMEOUT = 60
=end

end
