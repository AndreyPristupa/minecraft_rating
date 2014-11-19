# config valid only for Capistrano 3.1
lock '3.2.1'

# require 'bundler/capistrano';

set :application, 'minecraft_rating'
set :repo_url, 'https://github.com/AndreyPristupa/minecraft_rating.git'

set :linked_dirs, %w(public/uploads)
# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default deploy_to directory is /var/www/my_app
set :deploy_to, '/home/unrealm/webapps/minecraft_rating'
set :linked_dirs, fetch(:linked_dirs) + %w{public/system public/uploads}
set :default_env, {
    'PATH' => "#{deploy_to}/bin:$PATH",
    'GEM_HOME' => "#{deploy_to}/gems",
    'RUBYLIB' => "#{deploy_to}/lib"
}

set :rake, 'bundle exec rake'

# default_run_options[:pty] = true

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# set :linked_files, %w{config/database.yml}

# Default value for linked_dirs is []
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
      execute "#{deploy_to}/bin/restart"
      # execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  task :link_production_db do
    on roles(:app), in: :sequence, wait: 5 do
      execute "ln -nfs #{deploy_to}/shared/config/database.yml #{release_path}/config/database.yml"
    end
  end

  # task :bundle do
  #   on roles(:app) do
  #     execute "cd #{deploy_to} && bundle install --without development test"
  #   end
  # end

  task :assets_precompile do
    on roles(:app) do
      execute "cd #{release_path} && RAILS_ENV=production GEM_HOME=/home/unrealm/webapps/minecraft_rating/gems PATH=/home/unrealm/webapps/minecraft_rating/bin:/usr/local/bin:$PATH bundle exec rake assets:precompile"
    end
  end

  after :publishing, :link_production_db
  after :assets_precompile, :link_production_db
  after :link_production_db, :restart
  # after :bundle, :restart

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end
end




