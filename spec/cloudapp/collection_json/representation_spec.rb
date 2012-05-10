require 'helper'

require 'cloudapp/collection_json/representation'

describe CloudApp::CollectionJson::Representation do
  let(:response)       { stub :response, status: status }
  let(:status)         { 200 }
  let(:representation) {{
    'collection' => {
      'href'  => href,
      'items' => []
    }
  }}
  let(:href) { stub }
  subject    { representation }
  before do
    representation.extend CloudApp::CollectionJson::Representation
    representation.stub __response__: response
  end

  its(:href) { should eq(href) }

  describe '#authorized?' do
    it { should be_authorized }

    context 'unauthorized status' do
      let(:status) { 401 }
      it { should_not be_authorized }
    end
  end

  describe '#unauthorized?' do
    it { should_not be_unauthorized }

    context 'unauthorized status' do
      let(:status) { 401 }
      it { should be_unauthorized }
    end
  end

  describe '#collection_links' do
    its(:collection_links) { should be_empty }

    context 'with collection links' do
      let(:links) {[
        { 'rel' => 'next', 'href' => '/next' },
        { 'rel' => 'prev', 'href' => '/prev' }
      ]}
      before do representation['collection']['links'] = links end

      its(:collection_links) { should have(2).items }

      it 'presents links' do
        subject.collection_links.find {|link| link.rel == 'next' }.
          href.should eq('/next')
        subject.collection_links.find {|link| link.rel == 'prev' }.
          href.should eq('/prev')
      end
    end
  end

  describe '#items' do
    it 'is empty' do
      subject.items(stub(:item_source)).should be_empty
    end

    context 'with items' do
      let(:items)       {[ stub(:item1),      stub(:item2) ]}
      let(:item_data)   {[ stub(:item_data1), stub(:item_data2) ]}
      let(:item_source) { ->(item) {
        if item == item_data[0]
          items[0]
        elsif item == item_data[1]
          items[1]
        end
      }}
      before do representation['collection']['items'] = item_data end

      it 'should have items' do
        subject.items(item_source).should eq(items)
      end
    end
  end

  describe '#templates' do
    it 'is nil' do
      subject.template(stub(:template_source)).should be_nil
    end

    context 'with a template' do
      let(:template)        { stub :template }
      let(:template_data)   { stub :template_data }
      let(:template_source) { ->(item) { template if item == template_data }}
      before do representation['collection']['template'] = template_data end

      it 'finds the template' do
        subject.template(template_source).should eq(template)
      end
    end
  end

  describe '#queries' do
    it 'is nil' do
      subject.queries(stub(:query_source)).should be_nil
    end

    context 'with queries' do
      let(:queries)      {[ stub(:query1),      stub(:query2) ]}
      let(:query_data)   {[ stub(:query_data1), stub(:query_data2) ]}
      let(:query_source) { ->(query) { queries.at(query_data.index(query)) }}
      before do representation['collection']['queries'] = query_data end

      it 'should have queries' do
        subject.queries(query_source).should eq(queries)
      end
    end
  end

  describe '#query' do
    it 'is nil' do
      subject.query('rel', stub(:query_source)).should be_nil
    end

    context 'with queries' do
      let(:queries)      {[ stub(:query1, rel: 'one'),
                            stub(:query2, rel: 'two') ]}
      let(:query_data)   {[ stub(:query_data1), stub(:query_data2) ]}
      let(:query_source) { ->(query) { queries.at(query_data.index(query)) }}
      before do representation['collection']['queries'] = query_data end

      it 'finds the query by rel' do
        subject.query('one', query_source).should eq(queries.first)
      end
    end
  end
end
