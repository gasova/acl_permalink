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
  autoload :Reserved,   "acl_permalink/reserved"
  autoload :Scoped,     "acl_permalink/scoped"
  autoload :Slugged,    "acl_permalink/slugged"

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
  def self.table_name_prefix
    "#{ActiveRecord::Base.table_name_prefix}"
    #"#{ActiveRecord::Base.table_name_prefix}acl_permalink_slugs"
  end
end
