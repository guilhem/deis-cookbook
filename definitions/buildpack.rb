
define :buildpack, :name => nil, :git_url => nil, :target => nil do

  name = params[:name]
  git_url = params[:git_url]
  target = params[:target]

  git_url = "git://github.com/heroku/heroku-buildpack-#{name}.git" unless git_url

  git target do
    repository git_url
    reference 'master'
    action :checkout
  end
end
