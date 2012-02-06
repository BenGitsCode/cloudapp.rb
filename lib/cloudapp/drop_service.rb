require 'leadlight'
require 'addressable/uri'
require 'cloudapp/digestable_typhoeus'

# Leadlight service for mucking about with drops in the CloudApp API.
#
# Usage:
#
#   service = DropSerivce.as_identity email:    'arthur@dent.com',
#                                     password: 'towel'
#
#   # List all your drops
#   service.drops
#
#   # Create a bookmark
#   service.create url: 'http://getcloudapp.com', name: 'CloudApp'
#
#   # Upload a file
#   service.create path: #<Pathname>, name: 'Screen shot'
#
#   # List all your trashed drops
#   service.trash
#
#   # Delete a drop
#   service.drops.get(123).destroy
#
#   # Delete a drop from the trash
#   service.trash.get(123).destroy
#
#   # Restore a drop from the trash
#   service.trash.get(123).restore
#
module CloudApp
  class DropService
    Leadlight.build_connection_common do |c|
      c.request :multipart
      c.request :url_encoded
      c.adapter :digestable_typhoeus
    end

    Leadlight.build_service(self) do
      url 'http://my.cl.ly'

      # Add links present in the response body.
      #   { links: { self: "...", next: "...", prev: "..." } }
      tint 'links' do
        match Hash
        match { key? 'links' }
        self['links'].each do |rel, href|
          add_link href, rel
        end
      end

      tint 'root' do
        match_path '/'
        add_link   '/items?api_version=1.2', 'drops', 'List owned drops'
        add_link   '/items?api_version=1.2&deleted=true', 'trash', 'List owned, trashed drops'
      end

      tint 'create' do
        match_path '/items'
        # use "#{__location__}/new" when api_version isn't required in the query
        # string.
        add_link '/items/new', 'create_file', 'Create a new file drop'
      end

      # Add a rel=child link for each item in the list.
      #   { items: [{ id: 123, href: "..."}] }
      tint 'drops' do
        match_path '/items'
        match { key? 'items' }
        add_link_set 'child', :get do
          self['items'].map do |item|
            { href: item['href'], title: item['id'] }
          end
        end
      end

      # Add convenience methods on a drop representation to destroy and restore
      # from the trash.
      tint 'drop' do
        match_template '/items/{id}'
        extend do
          def destroy
            link('self').delete.
              raise_on_error.submit_and_wait
          end

          def restore
            link('self').put({}, deleted: true, item: { deleted_at: nil }).
              raise_on_error.submit_and_wait
          end
        end
      end
    end

    def identity=(identity)
      connection.options[:authentication] = { username: identity.email,
                                              password: identity.password }
    end

    def self.as_identity(identity, service_options = {})
      new(service_options).tap do |service|
        service.identity = identity
      end
    end

    def drops
      root.drops['items']
    end

    def trash
      root.trash['items']
    end

    def create(attributes)
      body = { item: {}}

      body[:item][:name]         = attributes[:name] if attributes.key? :name
      body[:item][:redirect_url] = attributes[:url]  if attributes.key? :url

      if attributes.key? :path
        create_file attributes[:path], body
      else
        create_bookmark body
      end
    end

    protected

    def create_bookmark(body)
      root.link('drops').post({}, body).raise_on_error.
        submit_and_wait do |new_drop|
          return new_drop
        end
    end

    def create_file(path, body)
      root.drops.link('create_file').get.raise_on_error.
        submit_and_wait do |details|
          uri     = Addressable::URI.parse details['url']
          file    = Faraday::UploadIO.new File.open(path), 'image/png'
          payload = details['params'].merge file: file

          conn = Faraday.new(url: uri.site) do |builder|
            builder.request :multipart
            builder.request :url_encoded
            builder.adapter :typhoeus
          end

          conn.post(uri.request_uri, payload).on_complete do |env|
            get(env[:response_headers]['Location']).raise_on_error.
              submit_and_wait { |created| return created }
          end
        end
    end
  end
end
