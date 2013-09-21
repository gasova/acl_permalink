require File.expand_path("../test/helper", __FILE__)
require "ffaker"

N = 1000

def transaction
  ActiveRecord::Base.transaction { yield ; raise ActiveRecord::Rollback }
end

class Array
  def rand
    self[Kernel.rand(length)]
  end
end

Book = Class.new ActiveRecord::Base

class Journalist < ActiveRecord::Base
  extend AclPermalink
  acl_permalink :name, :use => :slugged
end

class Manual < ActiveRecord::Base
  extend AclPermalink
  acl_permalink :name, :use => :history
end

BOOKS       = []
JOURNALISTS = []
MANUALS     = []

100.times do
  name = Faker::Name.name
  BOOKS       << (Book.create! :name => name).id
  JOURNALISTS << (Journalist.create! :name => name).acl_permalink
  MANUALS     << (Manual.create! :name => name).acl_permalink
end

ActiveRecord::Base.connection.execute "UPDATE manuals SET slug = NULL"

Benchmark.bmbm do |x|
  x.report 'find (without AclPermalink)' do
    N.times {Book.find BOOKS.rand}
  end
  x.report 'find (in-table slug)' do
    N.times {Journalist.find JOURNALISTS.rand}
  end
  x.report 'find (external slug)' do
    N.times {Manual.find MANUALS.rand}
  end

  x.report 'insert (without AclPermalink)' do
    N.times {transaction {Book.create :name => Faker::Name.name}}
  end

  x.report 'insert (in-table-slug)' do
    N.times {transaction {Journalist.create :name => Faker::Name.name}}
  end

  x.report 'insert (external slug)' do
    N.times {transaction {Manual.create :name => Faker::Name.name}}
  end
end
