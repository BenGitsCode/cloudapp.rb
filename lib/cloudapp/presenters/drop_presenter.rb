require 'delegate'

module CloudApp
  class DropPresenter < SimpleDelegator
    def present
      pretty
    end

    protected

    def pretty
      <<-PRETTY.chomp
Details
  Name:     #{ name }
  Views:    #{ views }
  Privacy:  #{ privacy_label }

Links
  Share:    #{ share_url }
  Embed:    #{ embed_url }
  Download: #{ download_url }
  Href:     #{ href }
PRETTY
    end

    def privacy_label
      private? ? 'Private' : 'Not Private'
    end
  end
end
