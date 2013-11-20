require 'httparty'

module Rack
  class Auditor
    ROOT_URL = 'http://icis-identity-example.herokuapp.com/api/v1/verify.json'

    def initialize(app, root_uri = 'http://snowflake.dev/')
      @app, @root_uri = app, root_uri
    end

    def call(env)
      key    = env['HTTP_X_API_KEY']
      secret = env['HTTP_X_API_SECRET']

      return forbidden unless key && secret

      response = HTTParty.get "#{@root_uri}?api_key=#{key}&api_secret=#{secret}"

      case response.code
      when 403
        forbidden
      when 404
        error_code(404, 'Not Found')
      when 500
        error_code(500, 'Server Error')
      when 503
        error_code(503, 'Maintenance')
      when 504
        error_code(504, 'System Down')
      end

      @app.call(env)
    end

    private
    def forbidden
      error_code(403, 'Unauthorized')
    end

    def error_code(code, message)
      [code, {'Content-Type' => 'text/plain'}, [message]]
    end
  end
end
