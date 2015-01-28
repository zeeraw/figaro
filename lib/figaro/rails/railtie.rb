module Figaro
  module Rails
    class Railtie < ::Rails::Railtie
      config.before_configuration do
        Figaro.load
        ::ENV["DATABASE_URL"] ||= Figaro.env.database_url
      end
    end
  end
end
