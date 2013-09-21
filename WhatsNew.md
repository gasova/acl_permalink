# What's New in AclPermalink 4?

## Back to basics

AclPermalink is mostly a different codebase from AclPermalink 3. However, this isn't
the "big rewrite," it's the "small rewrite:"

Adding new features with each release is not sustainable. This release *removes*
features, but makes it possible to add them back as addons. We can also remove
some complexity by relying on the better default functionality provided by newer
versions of Active Support and Active Record.

Here's what's changed:

## New configuration and setup

AclPermalink is no longer added to Active Record by default, you must explicitly
add it to each model you want to use it in. The method and options have also
changed:

    # AclPermalink 3
    class Post < ActiveRecord::Base
      has_acl_permalink :title, :use_slugs => true
    end

    # AclPermalink 4
    class Post < ActiveRecord::Base
      extend AclPermalink
      acl_permalink :title, :use => :slugged
    end

It also adds a new "defaults" method for configuring all models:

    AclPermalink.defaults do |config|
      config.use :slugged, :reserved
      config.base = :name
    end

## Active Record 3+ only

For 2.3 support, you can use AclPermalink 3.x, which will continue to be
maintained until people don't want it any more.

## In-table slugs

AclPermalink no longer creates a separate slugs table - it just stores the
generated slug value in the model table, which is simpler, faster and what most
want by default. Keeping slug history in a separate table is an
{AclPermalink::History optional add-on} for AclPermalink 4.

## No more multiple finds

    Person.find "joe-schmoe"               # Supported
    Person.find ["joe-schmoe", "john-doe"] # No longer supported

If you want find by more than one friendly id, build your own query:

    Person.where(:slug => ["joe-schmoe", "john-doe"])

This lets us do *far* less monkeypatching in Active Record. How much less?
AclPermalink overrides the base find with a mere 2 lines of code, and otherwise
changes nothing else. This means more stability and less breakage between Rails
updates.

## No more finder status

AclPermalink 3 offered finder statuses to help you determine when an outdated
or non-friendly id was used to find the record, so that you could decide whether
to permanently redirect to the canonical URL. However, there's a simpler way to
do that, so this feature has been removed:

    if request.path != person_path(@person)
      return redirect_to @person, :status => :moved_permanently
    end

## Bye-bye Babosa

[Babosa](http://github.com/norman/babosa) is AclPermalink 3's slugging library.

AclPermalink 4 doesn't use it by default because the most important pieces of it
were already accepted into Active Support 3.

However, Babosa is still useful, for example, for idiomatically transliterating
Cyrillic ([or other
language](https://github.com/norman/babosa/tree/master/lib/babosa/transliterator))
strings to ASCII. It's very easy to include - just override
`#normalize_acl_permalink` in your model:

    class MyModel < ActiveRecord::Base
      ...

      def normalize_acl_permalink(text)
        text.to_slug.normalize! :transliterations => :russian
      end
    end
