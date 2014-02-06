class CB::Client::Session

  include CB::Client::Connection

  attr_reader :key, :secret

  def initialize key, secret, raise_errors=true
    @key    = key
    @secret = secret
    @raise  = raise_errors
  end

  def home_contents options={}
    api_get '/api/home/contents', options
  end

  def section_contents section_slug, options={}
    api_get "/api/sections/#{section_slug}/contents", options
  end

  def section_content section_slug, content_slug, options={}
    api_get "/api/sections/#{section_slug}/contents/#{content_slug}", options
  end

  def new_section_content section_slug, options={}
    api_get "/api/sections/#{section_slug}/contents/new", options
  end

  def create_section_content section_slug, content_params, options={}
    api_post "/api/sections/#{section_slug}/contents", {content: content_params}, options
  end

  def contents options={}
    api_get "/api/contents", options
  end

  def content content_slug, options={}
    api_get "/api/contents/#{content_slug}", options
  end

private

  def api_get url, options
    api_call :get, url, nil, options
  end

  def api_post url, form_params, options
    api_call :post, url, form_params, options
  end

  def api_call verb, url, form_params, options
    conn   = get_connection(url: CB::Client.configuration.api_url)

    context = (options[:context].join(',') if options[:context].respond_to?(:join))
    (conn.params['context'] = context         ) if context
    (conn.params['page']    = options[:page]  ) if options[:page] && options[:page] != ''

    conn.headers['Accept']       = 'application/json'
    conn.headers['CB-KEY']       = key.to_s
    conn.headers['CB-SECRET']    = secret.to_s

    if options[:only_curl]
      api_curl_command verb, conn, url, form_params
    else
      if @raise
        perform_request!(verb, conn, url, form_params)
      else
        perform_request(verb, conn, url, form_params)
      end
    end
  end

  def api_curl_command verb, conn, url, form_params
    [true, "curl -X #{verb.to_s.upcase} '#{conn.build_url(url)}' -H 'Accept:#{conn.headers['Accept']}' -H 'CB-KEY:#{conn.headers['CB-KEY']}' -H 'CB-SECRET:#{conn.headers['CB-SECRET']}' -i"]
  end

end