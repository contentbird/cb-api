require 'spec_helper'
require 'json'

describe CB::Client::Session do

  subject { CB::Client::Session.new('id', 'token', nil, false) }

  describe '#initialize' do
    it 'creates a new Client service object with given key and secret' do
      subject.key.should eq 'id'
      subject.secret.should eq 'token'
    end
  end

  describe '#api_get and #api_post' do
    before do
      @headers = { 'CB-KEY' => subject.key, 'CB-SECRET' => subject.secret, 'Accept' => 'application/json'}
    end
    describe '#api_get' do
      before do
        url                        = 'https://contentbird.herokuapp.com/api/some/url?context=some,data'
        paginated_url              = 'https://contentbird.herokuapp.com/api/some/url?context=some,data&page=3'
        @stubbed_request           = stub_request(:get, url).with(headers: @headers)
        @stubbed_paginated_request = stub_request(:get, paginated_url).with(headers: @headers)
      end

      it 'makes an HTTP request to the given url using its credentials and forwarding the given options params' do
        @stubbed_request.to_return(status: 200, body:   {result: ['two', 'contents'], sections: ['two', 'sections']}.to_json)
        @stubbed_paginated_request.to_return(status: 200, body:   {result: ['page 3', 'contents'], sections: ['two', 'sections']}.to_json)

        subject.send(:api_get, '/api/some/url', context: [:some, :data]).should eq [true, {result: ['two', 'contents'], sections: ['two', 'sections']}]
        subject.send(:api_get, '/api/some/url', context: [:some, :data], page: 3).should eq [true, {result: ['page 3', 'contents'], sections: ['two', 'sections']}]
      end

      it 'returns error with message when WS replies with 403' do
        @stubbed_request.to_return(status: 403, body: {message: 'no channel matching your credentials'}.to_json)

        subject.send(:api_get, '/api/some/url', context: [:some, :data]).should eq [false, {message: 'no channel matching your credentials'}]
      end

      it 'returns error with message when WS replies with 404' do
        @stubbed_request.to_return(status: 404, body: {message: 'no channel with this prefix'}.to_json)

        subject.send(:api_get, '/api/some/url', context: [:some, :data]).should eq [false, {message: 'no channel with this prefix'}]
      end

      it 'returns WS message when WS replies with 500' do
        @stubbed_request.to_return(status: 500, body:   {message: 'an error occurred'}.to_json)

        subject.send(:api_get, '/api/some/url', context: [:some, :data]).should eq [false, {message: 'an error occurred'}]
      end

      it 'returns timeout message when WS timeout' do
        @stubbed_request.to_timeout

        subject.send(:api_get, '/api/some/url', context: [:some, :data]).should eq [false, {message: 'Timeout'}]
      end

      it 'does not call the API and returns a curl command if only_curl: true is passed in the options' do
        @stubbed_paginated_request.should_not have_been_requested

        subject.send(:api_get, '/api/some/url', context: [:some, :data], page: 3, only_curl: true)
               .should eq [true, "curl -X GET 'https://contentbird.herokuapp.com/api/some/url?context=some%2Cdata&page=3' -H 'Accept:application/json' -H 'Accept-Language:' -H 'CB-KEY:id' -H 'CB-SECRET:token' -i"]
      end

      context 'given a session in raise_error mode' do
        before do
          @client = CB::Client::Session.new('id', 'token', nil)
        end

        it 'returns only the API response body, without splatting with a success flag' do
          @stubbed_request.to_return(status: 200, body:   {result: ['two', 'contents'], sections: ['two', 'sections']}.to_json)

          @client.send(:api_get, '/api/some/url', context: [:some, :data]).should eq({result: ['two', 'contents'], sections: ['two', 'sections']})
        end

        it 'raises a CB exception when WS replies with 443' do
          @stubbed_request.to_return(status: 403, body: {message: 'No channel matches your credentials'}.to_json)

          expect { @client.send(:api_get, '/api/some/url', context: [:some, :data]) }.to raise_error(CB::Client::ForbiddenError)
        end

        it 'raises a CB exception when WS replies with 404' do
          @stubbed_request.to_return(status: 404, body: {message: 'no channel with this prefix'}.to_json)

          expect { @client.send(:api_get, '/api/some/url', context: [:some, :data]) }.to raise_error(CB::Client::NotFoundError)
        end

        it 'raises a CB exception when WS replies with 500' do
          @stubbed_request.to_return(status: 500, body: {message: 'an error occurred'}.to_json)

          expect { @client.send(:api_get, '/api/some/url', context: [:some, :data]) }.to raise_error(CB::Client::AppError)
        end

        it 'raises a CB exception timeout when WS timeout' do
          @stubbed_request.to_timeout

          expect {@client.send(:api_get, '/api/some/url', context: [:some, :data])}.to raise_error(CB::Client::TimeoutError)
        end
      end
    end

    describe '#post_api' do
      before do
        url              = 'https://contentbird.herokuapp.com/api/some/url?context=some,data'
        @post_params      = {'content' => {'title' => 'my title', 'body' => 'my body'}}
        @stubbed_request = stub_request(:post, url).with(headers: @headers, body: @post_params)
      end

      it 'makes an HTTP request to the given url using its credentials and forwarding the given options params' do
        @stubbed_request.to_return(status: 200, body:   {result: ['two', 'contents'], sections: ['two', 'sections']}.to_json)

        subject.send(:api_post, '/api/some/url', @post_params, context: [:some, :data]).should eq [true, {result: ['two', 'contents'], sections: ['two', 'sections']}]
      end
    end

  end

  describe '#home_contents' do
    it 'makes an api call to /home/contents passing the context and pagination options in query string' do
      subject.stub(:api_get).with('/api/home/contents', context: [:sections]).and_return([true, {content: 'data'}])
      subject.stub(:api_get).with('/api/home/contents', context: [:sections], page: 2).and_return([true, {paginated: 'data'}])

      subject.home_contents(context: [:sections]).should eq [true, {content: 'data'}]
      subject.home_contents(context: [:sections], page: 2).should eq [true, {paginated: 'data'}]
    end
  end

  describe '#section_contents' do
    it 'makes an api call to /sections/(slug)/contents passing the context and pagination options in query string' do
      subject.stub(:api_get).with('/api/sections/my-section/contents', context: [:sections]).and_return([true, {content: 'data'}])
      subject.stub(:api_get).with('/api/sections/my-section/contents', context: [:sections], page: 3).and_return([true, {paginated: 'data'}])

      subject.section_contents('my-section', context: [:sections]).should eq [true, {content: 'data'}]
      subject.section_contents('my-section', context: [:sections], page: 3).should eq [true, {paginated: 'data'}]
    end
  end

  describe '#section_content' do
    it 'makes an api call to /sections/(slug)/contents/(slug) passing the context option in query string' do
      subject.stub(:api_get).with('/api/sections/my-section/contents/my-content', context: [:sections]).and_return([true, {content: 'data'}])
      subject.section_content('my-section', 'my-content', context: [:sections]).should eq [true, {content: 'data'}]
    end
  end

  describe '#content' do
    it 'makes an api call to /contents/(slug) passing the context option in query string' do
      subject.stub(:api_get).with('/api/contents/my-content', context: [:sections]).and_return([true, {content: 'data'}])
      subject.content('my-content', context: [:sections]).should eq [true, {content: 'data'}]
    end
  end

  describe '#contents' do
    it 'makes an api call to /contents passing the context and pagination options in query string' do
      subject.stub(:api_get).with('/api/contents', context: [:sections]).and_return([true, {content: 'data'}])
      subject.stub(:api_get).with('/api/contents', context: [:sections], page: 3).and_return([true, {paginated: 'data'}])

      subject.contents(context: [:sections]).should eq [true, {content: 'data'}]
      subject.contents(context: [:sections], page: 3).should eq [true, {paginated: 'data'}]
    end
  end

  describe '#new_section_content' do
    it 'makes an api call to /:section_slug/contents/new passing the context in query string' do
      subject.stub(:api_get).with('/api/sections/my-section/contents/new', context: [:sections, :html]).and_return([true, {content: 'data'}])

      subject.new_section_content('my-section', context: [:sections, :html]).should eq [true, {content: 'data'}]
    end
  end

  describe '#create_section_content' do
    it 'makes an api post call to /:section_slug/contents passing the content in query string' do
      subject.stub(:api_post).with('/api/sections/my-section/contents', {content: {'some' => 'data'}}, {context: [:sections, :html]}).and_return([true, {content: 'data'}])

      subject.create_section_content('my-section', {'some' => 'data'}, context: [:sections, :html]).should eq [true, {content: 'data'}]
    end
  end

end