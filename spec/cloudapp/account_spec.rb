require 'helper'

require 'cloudapp/account'

describe CloudApp::Account do
  let(:args)    { stub :args }
  let(:token)   { 'token' }
  let(:service) { stub :service, :token= => nil }
  let(:service_source)  { -> { service }}
  let(:drop_collection) { stub :drop_collection }
  before do
    stub_class 'CloudApp::DropCollection'
    CloudApp::Account.service_source = service_source
    CloudApp::DropCollection.stub new: drop_collection
  end

  after do
    if CloudApp::DropCollection.ancestors.include? Stubbed
      CloudApp.send :remove_const, :DropCollection
    end
  end

  describe '.using_token' do
    it 'constructs and returns a new Account' do
      CloudApp::Account.should_receive(:new).with(token)
      CloudApp::Account.using_token(token)
    end
  end

  describe '#drops' do
    let(:drops)           {[ stub(:drop) ]}
    subject { CloudApp::Account.new(token).drops(args) }
    before do service.stub(drops: drops) end

    it { should eq(drop_collection) }

    it 'delegates to the drop service' do
      service.should_receive(:drops).with(args)
      subject
    end

    it 'creates a drop collection' do
      CloudApp::DropCollection.should_receive(:new).with(drops)
      subject
    end
  end

  describe '#drop_at' do
    let(:drop) { stub :drop }
    subject { CloudApp::Account.new(token).drop_at(args) }
    before do service.stub(drop_at: drop) end

    it { should eq(drop_collection) }

    it 'delegates to the drop service' do
      service.should_receive(:drop_at).with(args)
      subject
    end

    it 'creates a drop collection' do
      CloudApp::DropCollection.should_receive(:new).with(drop)
      subject
    end
  end

  describe '#bookmark' do
    let(:drop) { stub :drop }
    subject { CloudApp::Account.new(token).bookmark(args) }
    before do service.stub(bookmark: drop) end

    it { should eq(drop_collection) }

    it 'delegates to the service' do
      service.should_receive(:bookmark).with(args)
      subject
    end

    it 'creates a drop collection' do
      CloudApp::DropCollection.should_receive(:new).with(drop)
      subject
    end
  end

  describe '#upload' do
    let(:drop) { stub :drop }
    subject { CloudApp::Account.new(token).upload(args) }
    before do service.stub(upload: drop) end

    it { should eq(drop_collection) }

    it 'delegates to the service' do
      service.should_receive(:upload).with(args)
      subject
    end

    it 'creates a drop collection' do
      CloudApp::DropCollection.should_receive(:new).with(drop)
      subject
    end
  end

  describe '#update' do
    let(:drop) { stub :drop }
    subject { CloudApp::Account.new(token).update(args) }
    before do service.stub(update: drop) end

    it { should eq(drop_collection) }

    it 'delegates to the drop service' do
      service.should_receive(:update).with(args)
      subject
    end

    it 'creates a drop collection' do
      CloudApp::DropCollection.should_receive(:new).with(drop)
      subject
    end
  end

  describe '#trash_drop' do
    let(:drop) { stub :drop }
    subject { CloudApp::Account.new(token).trash_drop(args) }
    before do service.stub(trash_drop: drop) end

    it { should eq(drop_collection) }

    it 'delegates to the service' do
      service.should_receive(:trash_drop).with(args)
      subject
    end

    it 'creates a drop collection' do
      CloudApp::DropCollection.should_receive(:new).with(drop)
      subject
    end
  end

  describe '#recover_drop' do
    let(:drop) { stub :drop }
    subject { CloudApp::Account.new(token).recover_drop(args) }
    before do service.stub(recover_drop: drop) end

    it { should eq(drop_collection) }

    it 'delegates to the service' do
      service.should_receive(:recover_drop).with(args)
      subject
    end

    it 'creates a drop collection' do
      CloudApp::DropCollection.should_receive(:new).with(drop)
      subject
    end
  end

  describe '#delete_drop' do
    it 'delegates to the service' do
      service.should_receive(:delete_drop).with(args)
      CloudApp::Account.new.delete_drop(args)
    end
  end

  describe '#download' do
  end
end
