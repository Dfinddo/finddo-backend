source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.7.1'

gem 'rails-erd', group: :development
# cpf/cnpj utils
gem 'cpf_cnpj', '0.5.0'
# serialização rápida
gem 'jsonapi-serializer', '2.0'
# paginação
gem 'kaminari', '1.2.1'
# geração de tokens jwt
gem 'jwt', '2.2.1'
# variaveis de ambiente
gem 'dotenv-rails', '2.7.5', groups: [:development, :test]
# Requests externos
gem 'httparty', '0.18.1'
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '6.0.3.2'
# Use postgresql as the database for Active Record
gem 'pg', '1.2.3'
# Use Puma as the app server
gem 'puma', '4.3.5'
# Token based authentication
gem 'devise_token_auth', '1.1.3'
# Serialize objects
gem 'active_model_serializers'
# Generate Fake data
gem 'faker', '2.10.1'
# Bucket S3 to store files
gem 'aws-sdk-s3', '1.74.0', require: false
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use ActiveStorage variant
# gem 'mini_magick', '~> 4.8'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '1.4.6', require: false

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
gem 'rack-cors', '1.1.1', :require => 'rack/cors'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end


# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
