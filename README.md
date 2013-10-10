# AclPermalink

AclPermalink is the "Swiss Army bulldozer" of slugging and permalink plugins for
Ruby on Rails. It allows you to create pretty URLs and work with human-friendly
strings as if they were numeric ids for Active Record models.

Using AclPermalink, it's easy to make your application use URLs like:

    http://example.com/states/washington

instead of:

    http://example.com/states/4323454


## AclPermalink Features

AclPermalink offers many advanced features, including: slug history and
versioning, i18n, Globalize support, scoped slugs, reserved words, and custom
slug generators.

## Version 1.x

AclPermalink 1.x is a fork of friendly_id 4.x found in https://github.com/norman/friendly_id/tree/4.0-stable 
Their original authors are Norman Clarke, Adrian Mugnolo and Emilio Tagua. The purpose of this fork is to learn 
Gem development and customize this library for my own needs...

## Rails Quickstart

    gem install acl_permalink

    rails new my_app

    cd my_app

    gem "acl_permalink"
    
    rails generate scaffold user name:string slug:string

    # edit db/migrate/*_create_users.rb
    add_index :users, :slug, unique: true

    rake db:migrate

    # edit app/models/user.rb
    class User < ActiveRecord::Base
      extend AclPermalink
      acl_permalink :name, use: :slugged
    end

    User.create! name: "Joe Schmoe"

    rails server

    GET http://localhost:3000/users/joe-schmoe

    # If you're adding AclPermalink to an existing app and need
    # to generate slugs for existing users, do this from the
    # console, runner, or add a Rake task:
    User.find_each(&:save)


## License

Fork Copyright (c) 2013 Gokce ASOVA released under the MIT license.
Original Copyright (c) 2008-2012 Norman Clarke and contributors, released under the MIT
license.

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
