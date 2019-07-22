require "byebug"

RAILS_REQUIREMENT = '~> 6.0.0.rc1'.freeze
  
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
    run "cp -r ../../exi-monolith ."
    git clone: "--quiet https://github.com/extrainteger/exi-monolith" unless File.exists? "lib/exi-monolith"
  end
end

def ask_database
  @database = ask("\n1.default/sqlite \n2.postgresql \n3.mysql \n \e[32m \n \e[1m \e[32m Which database would you like to use? \e[0m")
end

def override_database_yml
  case @database
  when "2"
    run 'rm config/database.yml'
    run 'cp lib/exi-monolith/config/postgresql_database.yml config/database.yml'
  when "3"
    run 'rm config/database.yml'
    run 'cp lib/exi-monolith/config/mysql_database.yml config/database.yml'
  end  
end

def assert_dependencies
  assert_minimum_rails_version
end

def ask_dependencies
  ask_database
end

def add_dependencies
  case @database
  when "2"
    gem 'pg'
    gsub_file "Gemfile", /.*?sqlite3.*\r?\n/, ""
  when "3"
    gem 'mysql2'
    gsub_file "Gemfile", /.*?sqlite3.*\r?\n/, ""
  end
end

assert_dependencies
ask_dependencies
add_dependencies
add_template_repository_to_source_path
override_database_yml
