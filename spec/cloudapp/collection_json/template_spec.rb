require 'helper'
require 'cloudapp/collection_json/item'

require 'cloudapp/collection_json/template'

describe CloudApp::CollectionJson::Template do
  let(:template_data) {{ 'data' => [] }}
  subject { CloudApp::CollectionJson::Template.new template_data }

  its(:rel)     { should be_nil }
  its(:enctype) { should be_nil }


  context 'with a rel' do
    let(:rel) { stub :rel }
    before do template_data['rel'] = rel end

    its(:rel) { should eq(rel) }
  end

  context 'with an encoding type' do
    let(:enctype) { stub :enctype }
    before do template_data['enctype'] = enctype end

    its(:enctype) { should eq(enctype) }
  end

  describe '#fill' do
    let(:email) { 'arthur@dent.com' }
    let(:template_data) {{
      'data' => [
        { 'name' => 'email', 'value' => '' },
        { 'name' => 'age',   'value' => 29 }
      ]
    }}

    it 'returns a filled template' do
      expected = { 'email' => email, 'age' => 29 }
      subject.fill('email' => email).should eq(expected)
    end

    it 'leaves data untouched' do
      subject.fill('email' => email)
      subject.data.should eq('email' => '', 'age' => 29)
    end

    it 'ignores attributes not in the template' do
      expected = { 'email' => email, 'age' => 29 }
      new_data = { 'email' => email, 'ignore' => 'me' }
      subject.fill(new_data).should eq(expected)
    end
  end
end
