# Boilerplate

The purpose of this [template](https://github.com/extrainteger/exi-monilith/blob/master/readme.md) is to accomodate monolith project including its dashboard.

The boilerplate contains :

1. ActiveAdmin
2. ActiveMaterial
3. ActiveMaterialIcon

# Dependencies

1. Rails 6.0.0.rc1 or newer

# Install

Assume we want to create a project named `Hello`

1. Create a new rails project `rails new hello -m https://raw.githubusercontent.com/extrainteger/exi-monilith/master/template.rb`
2. While installing in progress you will be asked some question

## Database

`Which database would you like to use?` 

`1` For default or Sqlite
`2` For PostgreSql
`3` For MySql

## Capistrano

`Do you want to use Capistrano?`

Answer `y` if you wish to use Capistrano

# Getting started

1. Go to project `cd hello`
2. Edit credential `rails credentials:edit --environment development`. Modify the content from [credentials/example.yml](https://github.com/extrainteger/exi-api/blob/master/credentials/example.yml)
3. Edit credential `rails credentials:edit --environment test`. Modify the content from [credentials/example.yml](https://github.com/extrainteger/exi-api/blob/master/credentials/example.yml)
4. Prepare database `rails db:create && rails db:migrate && rails seed:migrate`

# Dashboard

Create default admin user from your `rails c` :
```ruby
AdminUser.create email: "helmy@extrainteger.com", password: "yunan123", password_confirmation: "yunan123"
```

# Access

1. Start server `rails s`
2. Go to http://dashboard.lvh.me:3000/admin to check Dashboard

# Capistrano
