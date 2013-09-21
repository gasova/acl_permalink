# encoding: utf-8
require "thread"
require "acl_permalink/base"
require "acl_permalink/object_utils"
require "acl_permalink/configuration"
require "acl_permalink/finder_methods"

=begin

== About AclPermalink

AclPermalink is an add-on to Ruby's Active Record that allows you to replace ids
in your URLs with strings:

    # without AclPermalink
    http://example.com/states/4323454

    # with AclPermalink
    http://example.com/states/washington

It requires few changes to your application code and offers flexibility,
performance and a well-documented codebase.

=== Core Concepts

==== Slugs

The concept of "slugs[http://en.wikipedia.org/wiki/Slug_(web_publishing)]" is at
the heart of AclPermalink.

A slug is the part of a URL which identifies a page using human-readable
keywords, rather than an opaque identifier such as a numeric id. This can make
your application more friendly both for users and search engine.

==== Finders: Slugs Act Like Numeric IDs

To the extent possible, AclPermalink lets you treat text-based identifiers like
normal IDs. This means that you can perform finds with slugs just like you do
with numeric ids:

    Person.find(82542335)
    Person.find("joe")

=end
module AclPermalink

  @mutex = Mutex.new

  autoload :History,    "acl_permalink/history"
  autoload :Slug,       "acl_permalink/slug"
  autoload :SimpleI18n, "acl_permalink/simple_i18n"
  autoload :Reserved,   "acl_permalink/reserved"
  autoload :Scoped,     "acl_permalink/scoped"
  autoload :Slugged,    "acl_permalink/slugged"
  autoload :Globalize,  "acl_permalink/globalize"

  # AclPermalink takes advantage of `extended` to do basic model setup, primarily
  # extending {AclPermalink::Base} to add {AclPermalink::Base#acl_permalink
  # acl_permalink} as a class method.
  #
  # Previous versions of AclPermalink simply patched ActiveRecord::Base, but this
  # version tries to be less invasive.
  #
  # In addition to adding {AclPermalink::Base#acl_permalink acl_permalink}, the class
  # instance variable +@acl_permalink_config+ is added. This variable is an
  # instance of an anonymous subclass of {AclPermalink::Configuration}. This
  # allows subsequently loaded modules like {AclPermalink::Slugged} and
  # {AclPermalink::Scoped} to add functionality to the configuration class only
  # for the current class, rather than monkey patching
  # {AclPermalink::Configuration} directly. This isolates other models from large
  # feature changes an addon to AclPermalink could potentially introduce.
  #
  # The upshot of this is, you can have two Active Record models that both have
  # a @acl_permalink_config, but each config object can have different methods
  # and behaviors depending on what modules have been loaded, without
  # conflicts.  Keep this in mind if you're hacking on AclPermalink.
  #
  # For examples of this, see the source for {Scoped.included}.
  def self.extended(model_class)
    return if model_class.respond_to? :acl_permalink
    class << model_class
      alias relation_without_acl_permalink relation
    end
    model_class.instance_eval do
      extend Base
      @acl_permalink_config = Class.new(Configuration).new(self)
      AclPermalink.defaults.call @acl_permalink_config
    end
  end

  # Allow developers to `include` AclPermalink or `extend` it.
  def self.included(model_class)
    model_class.extend self
  end

  # Set global defaults for all models using AclPermalink.
  #
  # The default defaults are to use the +:reserved+ module and nothing else.
  #
  # @example
  #   AclPermalink.defaults do |config|
  #     config.base = :name
  #     config.use :slugged
  #   end
  def self.defaults(&block)
    @mutex.synchronize do
      @defaults = block if block_given?
      @defaults ||= lambda {|config| config.use :reserved}
    end
  end

  # Set the ActiveRecord table name prefix to acl_permalink_
  #
  # This makes 'slugs' into 'acl_permalink_slugs' and also respects any
  # 'global' table_name_prefix set on ActiveRecord::Base.
  def self.table_name_prefix
    "#{ActiveRecord::Base.table_name_prefix}acl_permalink_"
  end
end
