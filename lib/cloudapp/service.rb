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
      response   = drops_at(href)
      drop       = DropCollection.new(response).first
      attributes = drop.data

      attributes['name']         = options.fetch(:name)         if options.has_key?(:name)
      attributes['private']      = options.fetch(:private)      if options.has_key?(:private)
      attributes['bookmark_url'] = options.fetch(:bookmark_url) if options.has_key?(:bookmark_url)

      data = response.template('/rels/create').fill(drop.data)

      post(drop.href, {}, data) do |response|
        return DropCollection.new(response)
      end
    end

    def bookmark(url, options = {})
      attributes = { 'bookmark_url' => url }
      attributes['name']    = options.fetch(:name)    if options.has_key?(:name)
      attributes['private'] = options.fetch(:private) if options.has_key?(:private)

      template = drops_at('/').template('/rels/create')
      data     = template.fill(attributes)

      post(template.href, {}, data) do |response|
        return DropCollection.new(response)
      end
    end

    def upload(path, options = {})
      attributes = { 'file_size' => FileTest.size(path) }

      template   = drops_at('/').template('/rels/create')
      data       = template.fill(attributes)

      post(template.href, {}, data) do |response|
        upload  = response.template('/rels/upload')
        uri     = Addressable::URI.parse upload.href
        file    = File.open path
        file_io = Faraday::UploadIO.new file, 'image/png'
        fields  = upload.fill('file' => file_io)

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
    end

    def recover(drop_ids)
      template = drops_at('/').template('/rels/recover')
      data     = template.fill('drop_ids' => drop_ids)

      post(template.href, {}, data) do |response|
        return SimpleResponse.new(response)
      end
    end

    def trash(drop_ids)
      template = drops_at('/').template('/rels/remove')
      data     = template.fill('drop_ids' => drop_ids)

      delete(template.href, {}, data) do |response|
        return SimpleResponse.new(response)
      end
    end

  private

    # TODO: Only pass `params` to `/rels/drops` href.
    def drops_at(href, params = {})
      get(href, params) do |response|
        return :unauthorized if response.__response__.status == 401

        drops_link = response.link('/rels/drops') { nil }
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
