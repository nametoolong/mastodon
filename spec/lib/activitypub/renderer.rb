# frozen_string_literal: true

require 'rails_helper'

describe ActivityPub::Renderer do
  context 'when rendering :note' do
    let!(:account) { Fabricate(:account) }
    let!(:other)   { Fabricate(:account) }
    let!(:parent)  { Fabricate(:status, account: account, visibility: :public) }
    let!(:reply1)  { Fabricate(:status, account: account, thread: parent, visibility: :public) }
    let!(:reply2)  { Fabricate(:status, account: account, thread: parent, visibility: :public) }
    let!(:reply3)  { Fabricate(:status, account: other, thread: parent, visibility: :public) }
    let!(:reply4)  { Fabricate(:status, account: account, thread: parent, visibility: :public) }
    let!(:reply5)  { Fabricate(:status, account: account, thread: parent, visibility: :direct) }

    subject { Oj.load(Oj.dump(ActivityPub::Renderer.new(:note, parent).render)) }

    it 'has a Note type' do
      expect(subject['type']).to eql('Note')
    end

    it 'has a replies collection' do
      expect(subject['replies']['type']).to eql('Collection')
    end

    it 'has a replies collection with a first Page' do
      expect(subject['replies']['first']['type']).to eql('CollectionPage')
    end

    it 'includes public self-replies in its replies collection' do
      expect(subject['replies']['first']['items']).to include(reply1.uri, reply2.uri, reply4.uri)
    end

    it 'does not include replies from others in its replies collection' do
      expect(subject['replies']['first']['items']).to_not include(reply3.uri)
    end

    it 'does not include replies with direct visibility in its replies collection' do
      expect(subject['replies']['first']['items']).to_not include(reply5.uri)
    end
  end

  context 'when rendering :update_note' do
    let!(:account) { Fabricate(:account) }
    let!(:poll)    { Fabricate(:poll, account: account) }
    let!(:status)  { Fabricate(:status, account: account, poll: poll) }

    subject { Oj.load(Oj.dump(ActivityPub::Renderer.new(:update_note, status).render)) }

    it 'has a Update type' do
      expect(subject['type']).to eql('Update')
    end

    it 'has an object with Question type' do
      expect(subject['object']['type']).to eql('Question')
    end

    it 'has the correct actor URI set' do
      expect(subject['actor']).to eql(ActivityPub::TagManager.instance.uri_for(account))
    end
  end
end
