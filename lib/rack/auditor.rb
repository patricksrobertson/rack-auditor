require 'httparty'

module Rack
  class Auditor
    def initialize(app, options = {})
      @app        = app
      @root_uri   = options[:root_uri] || 'http://snowflake.dev/'
      @dev_mode   = options[:dev_mode] || false
      @api_prefix = options[:api_prefix] || ''
      @access_method = options[:access_method] || :key #key or token
    end

    def call(env)
      unless @dev_mode || inappropriate_request(env)
        case @access_method
        when :key
          key    = env['HTTP_X_API_KEY']
          secret = env['HTTP_X_API_SECRET']

          return forbidden unless key && secret
          response = HTTParty.get "#{@root_uri}?api_key=#{key}&api_secret=#{secret}"
        when :token
          token  = env['HTTP_X_ACCESS_TOKEN']

          return forbidden unless token
          response = HTTParty.get "#{@root_uri}?acess_token=#{token}"
        end

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

    def inappropriate_request(env)
      return false if @api_prefix == ''

      uri = env['REQUEST_URI']
      return false if uri.match(@api_prefix)

      true
    end
  end
end
