# Provides data fields for authentication.
# (Currently just password)
class BrokerAuthenticationData

  # The configured message-broker password - nil if not found
  def broker_password
    ENV["REDISCLI_AUTH"]
  end
end
