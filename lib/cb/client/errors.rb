module CB
  module Client
    class AppError < StandardError; end
    class TimeoutError < StandardError; end
    class NotFoundError < StandardError; end
  end
end