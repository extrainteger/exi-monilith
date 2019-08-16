require "date"

RAILS_REQUIREMENT = '6.0.0.rc1'.freeze

def assert_minimum_rails_version
  requirement = Gem::Requirement.new(RAILS_REQUIREMENT)
  rails_version = Gem::Version.new(Rails::VERSION::STRING)
  return if requirement.satisfied_by?(rails_version)

  prompt = "This template requires Rails #{RAILS_REQUIREMENT}. "\
          "You are using #{rails_version}. Continue anyway? (y/n)"
  exit 1 if no?(prompt)
end

def add_template_repository_to_source_path
  inside('lib') do
    run "cp -r ../../exi-monilith ."
    git clone: "--quiet https://github.com/extrainteger/exi-monilith" unless File.exists? "lib/exi-monilith"
  end
end

def ask_database
  @database = ask("\n1.default/sqlite \n2.postgresql \n3.mysql \n \e[32m \n \e[1m \e[32m Which database would you like to use? \e[0m")
end

def ask_capistrano
  @capistrano = ask("\e[1m \e[32m Do you want to use Capistrano? \e[0m (y / n)") == "y" ? true : false
end

def use_capistrano?
  @capistrano
end

def override_database_yml_with_default_setting
  case @database
  when "2"
    run 'rm config/database.yml'
    run 'cp /Users/asharmubasir/Exi/railsix/exi-monolith/config/postgres_default.yml config/database.yml'
  when "3"
    run 'rm config/database.yml'
    run 'cp /Users/asharmubasir/Exi/railsix/exi-monolith/config/mysql_default.yml config/database.yml'
  end
end

def override_database_yml_with_credentials
  case @database
  when "2"
    run 'rm config/database.yml'
    run 'cp /Users/asharmubasir/Exi/railsix/exi-monolith/config/postgres_database.yml config/database.yml'
  when "3"
    run 'rm config/database.yml'
    run 'cp /Users/asharmubasir/Exi/railsix/exi-monolith/config/mysql_database.yml config/database.yml'
  end
end

def postgre_uuid
  environment do <<-RUBY
    config.generators do |g|
      g.orm :active_record, primary_key_type: :uuid
    end
  RUBY
  end
  file "db/migrate/#{Time.now.strftime("%Y%m%d%H%M%S")}_enable_uuid_extension.rb", <<-RUBY
class EnableUuidExtension < ActiveRecord::Migration[6.0]
  def change
    enable_extension 'uuid-ossp'
    enable_extension 'pgcrypto'
  end
end  
  RUBY
end

def install_dependencies
  generate "active_admin:install"
  rails_command "seed_migration:install:migrations"
  generate "active_material_icon:install"
  # generate "rspec:install"
end

def prepare_environment
  run 'cp config/environments/production.rb config/environments/staging.rb'
  run 'cp config/webpack/production.js config/webpack/staging.js'
end

def boilerplate_models
  generate :model, "app_version", "name version_code:integer force_update:boolean"

  file "db/data/#{Time.now.strftime("%Y%m%d%H%M%S")}_add_initial_version.rb", <<-RUBY
class AddInitialVersion < SeedMigration::Migration
  def up
    AppVersion.create name: "Genesis", version_code: "0.0.0", force_update: false
  end

  def down

  end
end    
  RUBY
end

def boilerplate_dashboard
  run 'mv app/assets/stylesheets/active_admin.scss app/assets/stylesheets/active_admin.scss.ori'
  run 'mv app/assets/javascripts/active_admin.js app/assets/javascripts/active_admin.js.ori'
  run 'cp /Users/asharmubasir/Exi/railsix/exi-monolith/app/assets/stylesheets/active_admin.scss app/assets/stylesheets'
  run 'cp /Users/asharmubasir/Exi/railsix/exi-monolith/app/assets/javascripts/active_admin.js app/assets/javascripts'

  environment 'config.hosts << "dashboard.lvh.me"', env: 'development'

  generate "active_admin:resource app_version"

  insert_into_file "app/admin/app_versions.rb", "\n  permit_params :name, :version_code, :force_update", after: "ActiveAdmin.register AppVersion do"
end

def write_routes
  run 'cp config/routes.rb config/routes.rb.ori'

  gsub_file "config/routes.rb", "devise_for :admin_users, ActiveAdmin::Devise.config", ""
  gsub_file "config/routes.rb", "ActiveAdmin.routes(self)", ""
  route <<-RUBY
  constraints subdomain: Rails.application.credentials.subdomain[:dashboard] do
    devise_for :admin_users, ActiveAdmin::Devise.config
    ActiveAdmin.routes(self)
  end
  RUBY
end

def prepare_capistrano
  run "bundle exec cap install" if use_capistrano?
end

def setup_capistrano
  if use_capistrano?
    # Capfile
    gsub_file 'Capfile', '# require "capistrano/rvm"', 'require "capistrano/rvm"'
    gsub_file 'Capfile', '# require "capistrano/bundler"', 'require "capistrano/bundler"'
    gsub_file 'Capfile', '# require "capistrano/rails/assets"', 'require "capistrano/rails/assets"'
    gsub_file 'Capfile', '# require "capistrano/rails/migrations"', 'require "capistrano/rails/migrations"'
    insert_into_file "Capfile", "\nrequire 'capistrano/seed_migration_tasks'", after: '# require "capistrano/passenger"'
    insert_into_file "Capfile", "\nrequire 'capistrano3/unicorn'", after: "require 'capistrano/seed_migration_tasks'"
    insert_into_file "Capfile", "\nrequire 'capistrano/unicorn/monit'", after: "require 'capistrano3/unicorn'"

    # deploy.rb
    gsub_file "config/deploy.rb", '# append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system"', 'append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system"'
    insert_into_file "config/deploy.rb", "\n\nafter 'deploy:migrating', 'seed:migrate'", after: "# set :ssh_options, verify_host_key: :secure"
    
    # config/deploy/
    run 'rm config/deploy/staging.rb'
    run 'rm config/deploy/production.rb'
    run 'cp /Users/asharmubasir/Exi/railsix/exi-monolith/config/deploy/staging.rb config/deploy/example.rb'

    # config/unicorn
    run 'mkdir config/unicorn'
    run 'cp /Users/asharmubasir/Exi/railsix/exi-monolith/config/unicorn/production.rb config/unicorn/example.rb'
  end
end

def webpacker
  insert_into_file "config/webpacker.yml", "\n\nstaging:\n  <<: *default\n\n  compile: false\n\n  extract_css: true\n\n  cache_manifest: true", after: "  public_output_path: packs-test"
end

def add_gitignore
  insert_into_file ".gitignore", "\n\n/config/deploy/production.rb \n\n/config/unicorn/production.rb \n/config/unicorn/staging.rb \n\n/config/credentials/staging.key \n\n/config/credentials/production.key \n\n/config/credentials/development.yml.enc \n\n/config/credentials/test.yml.enc", after: ".yarn-integrity"
end

def assert_dependencies
  assert_minimum_rails_version
end

def ask_dependencies
  ask_database
  ask_capistrano
end

def add_dependencies
  case @database
  when "2"
    gsub_file "Gemfile", /.*?gem 'sqlite3'.*\r?\n/, "gem 'pg'\n"
  when "3"
    gsub_file "Gemfile", /.*?gem 'sqlite3'.*\r?\n/, "gem 'mysql2'\n"
  end

  if use_capistrano?
    gem_group :development do
      gem 'capistrano'
      gem 'capistrano-rails'
      gem 'capistrano3-unicorn'
      gem 'capistrano-rvm'
      gem 'capistrano-unicorn-monit', github: 'bypotatoes/capistrano-unicorn-monit'
    end

    gem_group :staging do
      gem 'unicorn'
    end
  
    gem_group :production do
      gem 'unicorn'
    end
  end
  
  gem 'devise'

  gem 'activeadmin'
  gem 'active_material', github: 'vigetlabs/active_material', branch: 'nh-responsive-redesign'
  gem 'active_material_icon' # ActiveMaterialIcon after active_admin and active_material

  gem 'seed_migration'
end

def setup_database
  override_database_yml_with_default_setting
  postgre_uuid if @database == "2"
end

def stop_spring
  run "spring stop"
end

def finishing
  run "cp lib/exi-monilith/readme.md boilerplate.md"

  say
  say
  say "================================================================================================="
  say 
  say 
  say "You have successfully installed the boilerplate", :green
  say
  say "Don't forget to store your credentials inside config/credentials/*.key into somewhere else safely"
  say
  say "If you lose those keys, you won't be able to read your credentials.", :red
  say
  say
  say "To get started :", :green
  say
  say "Follow the instruction https://github.com/extrainteger/exi-monilith/blob/master/readme.md#getting-started", :green
  say
  say
  say "================================================================================================="
end

assert_dependencies
# add_template_repository_to_source_path
ask_dependencies
add_dependencies
setup_database

after_bundle do
  stop_spring
  install_dependencies
  boilerplate_models
  boilerplate_dashboard
  write_routes
  override_database_yml_with_credentials
  prepare_environment
  prepare_capistrano
  setup_capistrano
  webpacker
  add_gitignore
  finishing
  stop_spring
  # remove_source
end
