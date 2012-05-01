require 'leadlight'
require 'cloudapp/collection_json'
require 'cloudapp/drop'
require 'cloudapp/drop_collection'

module CloudApp
  class Service
    Leadlight.build_service(self) do
      url 'http://api.getcloudapp.com'

      type_mapping 'application/vnd.collection+json',
                   CollectionJson::Representation,
                   CollectionJson::Type

      tint 'collection+json' do
        match_content_type 'application/vnd.collection+json'
        collection_links.each do |link|
          add_link link.href, link.rel
        end
      end
    end

    def initialize(*args)
      super
      logger.level = Logger::WARN
    end

    def token=(token)
      connection.token_auth token
    end

    def self.using_token(token)
      new.tap do |service|
        service.token = token
      end
    end

    def token_for_account(email, password)
      SimpleResponse.new request_token(email, password)
    end

    def drops(options = {})
      href   = options.fetch :href, '/'
      params = {}
      params[:filter] = options[:filter] if options.has_key?(:filter)
      DropCollection.new drops_at(href, params)
    end

    def drop_at(href)
      DropCollection.new drops_at(href)
    end

    def update(href, options = {})
      collection = drops_at href
      drop       = DropCollection.new(collection).first
      path       = options.fetch :path, nil
      attributes = drop.data.merge fetch_drop_attributes(options)
      data       = collection.template.fill attributes

      put(drop.href, {}, data) do |collection|
        if not path
          return DropCollection.new(collection)
        else
          return upload_file(path, collection)
        end
      end
    end

    def bookmark(url, options = {})
      attributes = fetch_drop_attributes options.merge(url: url)
      collection = drops_at('/')
      data       = collection.template.fill(attributes)

      post(collection.href, {}, data) do |response|
        return DropCollection.new(response)
      end
    end

    def upload(path, options = {})
      attributes = fetch_drop_attributes options.merge(path: path)
      collection = drops_at('/')
      data       = collection.template.fill(attributes)

      post(collection.href, {}, data) do |collection|
        return upload_file(path, collection)
      end
    end

    def trash_drop(href)
      update href, trash: true
    end

    def delete_drop(href)
      delete(href) do |response|
        return SimpleResponse.new(response)
      end
    end

  private

    # TODO: Only pass `params` to `drops` href.
    def drops_at(href, params = {})
      get(href, params) do |response|
        return :unauthorized if response.__response__.status == 401

        drops_link = response.link('drops') { nil }
        if drops_link
          return drops_at(drops_link.href, params)
        else
          return response
        end
      end
    end

    def request_token(email, password)
      authenticate_response = root
      data = authenticate_response.template.
               fill('email' => email, 'password' => password)

      post(authenticate_response.href, {}, data) do |response|
        return :unauthorized if response.__response__.status == 401
        return response.items.first.data['token']
      end
    end

    def fetch_drop_attributes(options)
      path = options.delete :path
      options[:file_size] = FileTest.size(path) if path
      { url:       'bookmark_url',
        file_size: 'file_size',
        name:      'name',
        private:   'private',
        trash:     'trash'
      }.each_with_object({}) do |(key, name), attributes|
        attributes[name] = options.fetch(key) if options.has_key?(key)
      end
    end

    def upload_file(path, collection)
      uri     = Addressable::URI.parse collection.href
      file    = File.open path
      file_io = Faraday::UploadIO.new file, 'image/png'
      fields  = collection.template.fill('file' => file_io)

      conn = Faraday.new(url: uri.site) do |builder|
        builder.request  :multipart
        builder.request  :url_encoded
        builder.response :logger, logger
        builder.adapter  :typhoeus
      end

      conn.post(uri.request_uri, fields).on_complete do |env|
        location = Addressable::URI.parse env[:response_headers]['Location']
        get(location) do |upload_response|
          return DropCollection.new(upload_response)
        end
      end
    end

    class SimpleResponse < SimpleDelegator
      def value
        __getobj__
      end

      def successful?
        not unauthorized?
      end

      def unauthorized?
        self == :unauthorized
      end
    end
  end
end
