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

  def api_get url, options
    api_call :get, url, nil, options
  end

  def api_post url, form_params, options
    api_call :post, url, form_params, options
  end

private
  def api_call verb, url, form_params, options
    conn   = get_connection(url: CB_API_URL.to_s)

    context = options[:context].try(:join, ',')
    (conn.params['context'] = context         ) if context
    (conn.params['page']    = options[:page]  ) if options[:page].present?

    conn.headers['Accept']       = 'application/json'
    conn.headers['CB-KEY']       = key.to_s
    conn.headers['CB-SECRET']    = secret.to_s
    if @raise
      perform_request!(verb, conn, url, form_params)
    else
      perform_request(verb, conn, url, form_params)
    end
  end

end