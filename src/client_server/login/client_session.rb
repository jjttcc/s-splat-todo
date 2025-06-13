class ClientSession

  public

  EXPIRATION_SECONDS = 24 * 60 * 60 * 2   # 2 days

  attr_reader :session_id
  attr_reader :user_id
  attr_reader :app_name
  attr_reader :creation_time
  attr_reader :expiration_time

  def expiration_secs
    EXPIRATION_SECONDS
  end

  private

  def initialize(sessid, user, appname)
    @session_id = sessid
    @user_id = user
    @app_name = appname
    @creation_time = Time.now
    @expiration_time = creation_time + EXPIRATION_SECONDS
  end

end
