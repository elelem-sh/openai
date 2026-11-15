# frozen_string_literal: true

RSpec.describe Elelem::OpenAI::Provider::HttpAdapter do
  def sent_headers(api_key)
    seen = nil
    conn = double("conn").tap { |c| allow(c).to receive(:request) { |req| seen = req } }
    http = double("http", "use_ssl=": nil, "read_timeout=": nil, "open_timeout=": nil).tap do |h|
      allow(h).to receive(:start).and_yield(conn)
    end
    allow(Net::HTTP).to receive(:new).and_return(http)
    adapter = described_class.new(read_timeout: 1, open_timeout: 1)
    adapter.post(URI("http://h/v1/chat/completions"), api_key: api_key, body: {})
    seen
  end

  it "sends the key as a bearer token" do
    expect(sent_headers("sk-test")["authorization"]).to eq("Bearer sk-test")
  end

  it "sends no authorization header without a key" do
    expect(sent_headers("")["authorization"]).to be_nil
  end
end
