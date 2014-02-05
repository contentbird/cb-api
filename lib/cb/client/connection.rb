module CB::Client::Connection

  def get_connection args
    Faraday.new(args)
  end

  def perform_request verb, conn, url, form_params=nil
    begin
      result = http_call(verb, conn, url, form_params)
    rescue Faraday::Error::TimeoutError
      return [false, message: 'Timeout']
    end
    case result.status
    when 200
      [true, JSON.parse(result.body).symbolize_keys]
    when 404
      [false, JSON.parse(result.body).symbolize_keys]
    when 500
      [false, JSON.parse(result.body).symbolize_keys]
    end
  end

  def perform_request! verb, conn, url, form_params=nil
    begin
      result = http_call(verb, conn, url, form_params)
    rescue Faraday::Error::TimeoutError
      raise CB::Client::TimeoutError, 'CB API Timeout'
    end
    case result.status
    when 200
      JSON.parse(result.body).symbolize_keys
    when 404
      raise CB::Client::NotFoundError, 'CB API Ressource not found'
    when 500
      raise CB::Client::AppError, 'CB API Application error'
    end
  end

private
  def http_call verb, conn, url, form_params=nil
    result = conn.public_send(verb) do |req|
      req.url url
      req.body = form_params if verb == :post
      req.options[:timeout]       = 5
      req.options[:open_timeout]  = 2
    end
  end

end