require 'rails_helper'

RSpec.describe RollingCache do
  subject { RollingCache.new('mastoduck:test', 50) }

  let(:account) { Account.new(id: 10, username: 'alice', domain: 'example.com', fields: [{'name' => 'First', 'value' => 'Value'}, {'name' => 'Second', 'value' => 'Thing'}]) }

  it 'serializes an object using marshal' do
    dumped = subject.dump(account)
    expect(dumped).to include('type' => 'marshal')
    expect(dumped).to have_key('content')
  end

  it 'plucks attributes into bson' do
    dumped = subject.dump(account, :id, :username, :domain)
    expect(dumped).to include('type' => 'bson')
    expect(dumped).to include('class' => 'Account')
    expect(dumped).to have_key('content')
  end

  it 'deserializes an object using marshal' do
    loaded = subject.load(subject.dump(account))
    expect(loaded.attributes).to eq(account.attributes)
  end

  it 'constructs an object from bson' do
    loaded = subject.load(subject.dump(account, :id, :username, :domain, :fields))
    expect(loaded.id).to eq(account.id)
    expect(loaded.username).to eq(account.username)
    expect(loaded.domain).to eq(account.domain)
    expect(loaded.fields.map(&:name)).to eq(account.fields.map(&:name))
    expect(loaded.fields.map(&:value)).to eq(account.fields.map(&:value))
  end

  it 'saves entries to redis' do
    loaded = subject.get(subject.push(account))
    expect(loaded.attributes).to eq(account.attributes)
  end

  it 'prunes entries in the cache' do
    old_id = subject.push(account)

    redis.pipelined do
      1000.times { subject.push(account, :id) }
    end

    expect(subject.load(old_id)).to be_nil

    # We use approximate: true so allow some more entries to survive
    expect(redis.xlen('mastoduck:test')).to be < 100
  end
end
