source 'https://rubygems.org'

gem 'chef', "~> 11"
gem "berkshelf", "~> 2.0.14"
gem 'knife-ec2'

group :test do
  gem "strainer", "~> 3.3.0"
  gem "rubocop"
  gem 'foodcritic', "~> 3.0.3"
end

group :integration do
  gem "test-kitchen"
  gem "kitchen-vagrant"
  gem "kitchen-docker"
end
