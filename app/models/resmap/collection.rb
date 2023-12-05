require "json"
require "net/http"
require "uri"

module ResourceMap
  class Collection
    def self.origin=(origin)
      @@origin = URI(origin)
    end
    
    def self.username=(username)
      @@username = URI(username)
    end
    
    def self.password=(password)
      @@password = URI(password)
    end
    
    def initialize(id)
      @id = id
    end
    
    def sites(**params)
      @sites ||= [].tap { |sites| each_site(**params) { |site| sites << site } }
    end
    
    def fields(&block)
      @fields ||= [].tap { |fields| each_field { |field| fields << field } }
    end
    
    def each_site(updated_since: nil, deleted_since: nil, locale: nil, &block)
      params = {}
      params[:updated_since] = updated_since.iso8601 if updated_since
      params[:deleted_since] = deleted_since.iso8601 if deleted_since
      params[:locale] = locale.to_s if locale
      query_params = URI.encode_www_form(params)
      
      find_each("/api/collections/#{@id}.json?#{query_params}") do |response|
        response["sites"].each { |site| yield site }
        response
      end
    end
    
    def each_field(&block)
      find_each("/api/collections/#{@id}/layers.json") do |response|
        if fields = response.dig(0, "fields")
          fields.each { |field| yield field }
        end
        response[0]
      end
    end

    private

    def find_each(request_uri)
      loop do
        response = yield request(request_uri)
        
        if next_page = response["nextPage"]
          request_uri = URI(next_page).request_uri
        else
          break
        end
      end
    end

    def request(request_uri)
      Net::HTTP.start(@@origin.host, @@origin.port, use_ssl: @@origin.scheme == "https") do |http|
        logger.info { "GET #{@@origin}#{request_uri}" }
        
        request = Net::HTTP::Get.new(request_uri)
        request.basic_auth(@@username, @@password)
        response = http.request(request)
        
        if response.code == "200"
          JSON.parse(response.body)
        else
          raise "ERROR: #{response.inspect}"
        end
      end
    end

    def logger
      @logger ||=
      if defined?(Rails)
        Rails.logger
      else
        Logger.new(STDERR)
      end
    end
  end
end
  