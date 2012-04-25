require 'helper'
require 'stringio'

require 'cloudapp/presenters/drop_presenter'

class FakeDrop
  attr_accessor :name, :views, :private, :href,
                :share_url, :embed_url, :download_url
  alias_method :private?, :private

  def initialize(options = {})
    @name         = options.fetch :name,         'Drop'
    @views        = options.fetch :views,        0
    @private      = options.fetch :private,      true
    @href         = options.fetch :href,         'http://href'
    @share_url    = options.fetch :share_url,    'http://share'
    @embed_url    = options.fetch :embed_url,    'http://embed'
    @download_url = options.fetch :download_url, 'http://download'
  end
end

describe CloudApp::DropPresenter do
  describe '#present' do
    let(:drop) { FakeDrop.new }
    subject    { CloudApp::DropPresenter.new(drop).present }

    it 'prints the drop' do
      expected = <<-DROP.chomp
Details
  Name:     Drop
  Views:    0
  Privacy:  Private

Links
  Share:    http://share
  Embed:    http://embed
  Download: http://download
  Href:     http://href
DROP

      subject.should eq(expected)
    end
  end
end
