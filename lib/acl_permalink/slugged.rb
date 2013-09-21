# encoding: utf-8
require "acl_permalink/slug_generator"

module AclPermalink
=begin

== Slugged Models

AclPermalink can use a separate column to store slugs for models which require
some text processing.

For example, blog applications typically use a post title to provide the basis
of a search engine friendly URL. Such identifiers typically lack uppercase
characters, use ASCII to approximate UTF-8 character, and strip out other
characters which may make them aesthetically unappealing or error-prone when
used in a URL.

    class Post < ActiveRecord::Base
      extend AclPermalink
      acl_permalink :title, :use => :slugged
    end

    @post = Post.create(:title => "This is the first post!")
    @post.acl_permalink   # returns "this-is-the-first-post"
    redirect_to @post   # the URL will be /posts/this-is-the-first-post

In general, use slugs by default unless you know for sure you don't need them.
To activate the slugging functionality, use the {AclPermalink::Slugged} module.

AclPermalink will generate slugs from a method or column that you specify, and
store them in a field in your model. By default, this field must be named
+:slug+, though you may change this using the
{AclPermalink::Slugged::Configuration#slug_column slug_column} configuration
option. You should add an index to this column, and in most cases, make it
unique. You may also wish to constrain it to NOT NULL, but this depends on your
app's behavior and requirements.

=== Example Setup

    # your model
    class Post < ActiveRecord::Base
      extend AclPermalink
      acl_permalink :title, :use => :slugged
      validates_presence_of :title, :slug, :body
    end

    # a migration
    class CreatePosts < ActiveRecord::Migration
      def self.up
        create_table :posts do |t|
          t.string :title, :null => false
          t.string :slug, :null => false
          t.text :body
        end

        add_index :posts, :slug, :unique => true
      end

      def self.down
        drop_table :posts
      end
    end

=== Working With Slugs

==== Formatting

By default, AclPermalink uses Active Support's
paramaterize[http://api.rubyonrails.org/classes/ActiveSupport/Inflector.html#method-i-parameterize]
method to create slugs. This method will intelligently replace spaces with
dashes, and Unicode Latin characters with ASCII approximations:

  movie = Movie.create! :title => "Der Preis fürs Überleben"
  movie.slug #=> "der-preis-furs-uberleben"

==== Uniqueness

When you try to insert a record that would generate a duplicate friendly id,
AclPermalink will append a sequence to the generated slug to ensure uniqueness:

  car = Car.create :title => "Peugot 206"
  car2 = Car.create :title => "Peugot 206"

  car.acl_permalink #=> "peugot-206"
  car2.acl_permalink #=> "peugot-206--2"

==== Sequence Separator - The Two Dashes

By default, AclPermalink uses two dashes to separate the slug from a sequence.

You can change this with the {AclPermalink::Slugged::Configuration#sequence_separator
sequence_separator} configuration option.

==== Column or Method?

AclPermalink always uses a method as the basis of the slug text - not a column. It
first glance, this may sound confusing, but remember that Active Record provides
methods for each column in a model's associated table, and that's what
AclPermalink uses.

Here's an example of a class that uses a custom method to generate the slug:

  class Person < ActiveRecord::Base
    acl_permalink :name_and_location
    def name_and_location
      "#{name} from #{location}"
    end
  end

  bob = Person.create! :name => "Bob Smith", :location => "New York City"
  bob.acl_permalink #=> "bob-smith-from-new-york-city"

==== Providing Your Own Slug Processing Method

You can override {AclPermalink::Slugged#normalize_acl_permalink} in your model for
total control over the slug format.

==== Deciding When to Generate New Slugs

Overriding {AclPermalink::Slugged#should_generate_new_acl_permalink?} lets you
control whether new friendly ids are created when a model is updated. For
example, if you only want to generate slugs once and then treat them as
read-only:

  class Post < ActiveRecord::Base
    extend AclPermalink
    acl_permalink :title, :use => :slugged

    def should_generate_new_acl_permalink?
      new_record?
    end
  end

  post = Post.create!(:title => "Hello world!")
  post.slug #=> "hello-world"
  post.title = "Hello there, world!"
  post.save!
  post.slug #=> "hello-world"

==== Locale-specific Transliterations

Active Support's +parameterize+ uses
transliterate[http://api.rubyonrails.org/classes/ActiveSupport/Inflector.html#method-i-transliterate],
which in turn can use I18n's transliteration rules to consider the current
locale when replacing Latin characters:

  # config/locales/de.yml
  de:
    i18n:
      transliterate:
        rule:
          ü: "ue"
          ö: "oe"
          etc...

  movie = Movie.create! :title => "Der Preis fürs Überleben"
  movie.slug #=> "der-preis-fuers-ueberleben"

This functionality was in fact taken from earlier versions of AclPermalink.

==== Gotchas: Common Problems

===== Slugs That Begin With Numbers

Ruby's `to_i` function casts strings to integers in such a way that +23abc.to_i+
returns 23. Because AclPermalink falls back to finding by numeric id, this means
that if you attempt to find a record with a non-existant slug, and that slug
begins with a number, your find will probably return the wrong record.

There are two fairly simple ways to avoid this:

* Use validations to ensure that slugs don't begin with numbers.
* Use explicit finders like +find_by_id+ to always find by the numeric id, or
  +find_by_slug+ to always find using the friendly id.

===== Concurrency Issues

AclPermalink uses a before_validation callback to generate and set the slug. This
means that if you create two model instances before saving them, it's possible
they will generate the same slug, and the second save will fail.

This can happen in two fairly normal cases: the first, when a model using nested
attributes creates more than one record for a model that uses acl_permalink. The
second, in concurrent code, either in threads or multiple processes.

To solve the nested attributes issue, I recommend simply avoiding them when
creating more than one nested record for a model that uses AclPermalink. See {this
Github issue}[https://github.com/norman/acl_permalink/issues/185] for discussion.

To solve the concurrency issue, I recommend locking the model's table against
inserts while when saving the record. See {this Github
issue}[https://github.com/norman/acl_permalink/issues/180] for discussion.

=end
  module Slugged

    # Sets up behavior and configuration options for AclPermalink's slugging
    # feature.
    def self.included(model_class)
      model_class.acl_permalink_config.instance_eval do
        self.class.send :include, Configuration
        self.slug_generator_class     ||= Class.new(SlugGenerator)
        defaults[:slug_column]        ||= 'slug'
        defaults[:sequence_separator] ||= '--'
      end
      model_class.before_validation :set_slug
    end

    # Process the given value to make it suitable for use as a slug.
    #
    # This method is not intended to be invoked directly; AclPermalink uses it
    # internaly to process strings into slugs.
    #
    # However, if AclPermalink's default slug generation doesn't suite your needs,
    # you can override this method in your model class to control exactly how
    # slugs are generated.
    #
    # === Example
    #
    #   class Person < ActiveRecord::Base
    #     acl_permalink :name_and_location
    #
    #     def name_and_location
    #       "#{name} from #{location}"
    #     end
    #
    #     # Use default slug, but upper case and with underscores
    #     def normalize_acl_permalink(string)
    #       super.upcase.gsub("-", "_")
    #     end
    #   end
    #
    #   bob = Person.create! :name => "Bob Smith", :location => "New York City"
    #   bob.acl_permalink #=> "BOB_SMITH_FROM_NEW_YORK_CITY"
    #
    # === More Resources
    #
    # You might want to look into Babosa[https://github.com/norman/babosa],
    # which is the slugging library used by AclPermalink prior to version 4, which
    # offers some specialized functionality missing from Active Support.
    #
    # @param [#to_s] value The value used as the basis of the slug.
    # @return The candidate slug text, without a sequence.
    def normalize_acl_permalink(value)
      value.to_s.parameterize
    end

    # Whether to generate a new slug.
    #
    # You can override this method in your model if, for example, you only want
    # slugs to be generated once, and then never updated.
    def should_generate_new_acl_permalink?
      base       = send(acl_permalink_config.base)
      slug_value = send(acl_permalink_config.slug_column)

      # If the slug base is nil, and the slug field is nil, then we're going to
      # leave the slug column NULL.
      return false if base.nil? && slug_value.nil?
      # Otherwise, if this is a new record, we're definitely going to try to
      # create a new slug.
      return true if new_record?
      slug_base = normalize_acl_permalink(base)
      separator = Regexp.escape acl_permalink_config.sequence_separator
      # If the slug base (with and without sequence) is different from either the current
      # friendly id or the slug value, then we'll generate a new acl_permalink.
      compare = (current_acl_permalink || slug_value)
      slug_base != compare && slug_base != compare.try(:sub, /#{separator}[\d]*\z/, '')
    end

    # Sets the slug.
    # FIXME: This method sucks and the logic is pretty dubious.
    def set_slug(normalized_slug = nil)
      if normalized_slug || should_generate_new_acl_permalink?
        normalized_slug ||= normalize_acl_permalink send(acl_permalink_config.base)
        generator = acl_permalink_config.slug_generator_class.new self, normalized_slug
        send "#{acl_permalink_config.slug_column}=", generator.generate
      end
    end
    private :set_slug

    # This module adds the +:slug_column+, and +:sequence_separator+, and
    # +:slug_generator_class+ configuration options to
    # {AclPermalink::Configuration AclPermalink::Configuration}.
    module Configuration
      attr_writer :slug_column, :sequence_separator
      attr_accessor :slug_generator_class

      # Makes AclPermalink use the slug column for querying.
      # @return String The slug column.
      def query_field
        slug_column
      end

      # The string used to separate a slug base from a numeric sequence.
      #
      # By default, +--+ is used to separate the slug from the sequence.
      # AclPermalink uses two dashes to distinguish sequences from slugs with
      # numbers in their name.
      #
      # You can change the default separator by setting the
      # {AclPermalink::Slugged::Configuration#sequence_separator
      # sequence_separator} configuration option.
      #
      # For obvious reasons, you should avoid setting it to "+-+" unless you're
      # sure you will never want to have a friendly id with a number in it.
      # @return String The sequence separator string. Defaults to "+--+".
      def sequence_separator
        @sequence_separator or defaults[:sequence_separator]
      end

      # The column that will be used to store the generated slug.
      def slug_column
        @slug_column or defaults[:slug_column]
      end
    end
  end
end
