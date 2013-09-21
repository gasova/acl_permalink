module AclPermalink
  # Utility methods for determining whether any object is a friendly id.
  #
  # Monkey-patching Object is a somewhat extreme measure not to be taken lightly
  # by libraries, but in this case I decided to do it because to me, it feels
  # cleaner than adding a module method to {AclPermalink}. I've given the methods
  # names that unambigously refer to the library of their origin, which should
  # be sufficient to avoid conflicts with other libraries.
  module ObjectUtils

    # True is the id is definitely friendly, false if definitely unfriendly,
    # else nil.
    #
    # An object is considired "definitely unfriendly" if its class is or
    # inherits from ActiveRecord::Base, Array, Hash, NilClass, Numeric, or
    # Symbol.
    #
    # An object is considered "definitely friendly" if it responds to +to_i+,
    # and its value when cast to an integer and then back to a string is
    # different from its value when merely cast to a string:
    #
    #   123.acl_permalink?                  #=> false
    #   :id.acl_permalink?                  #=> false
    #   {:name => 'joe'}.acl_permalink?     #=> false
    #   ['name = ?', 'joe'].acl_permalink?  #=> false
    #   nil.acl_permalink?                  #=> false
    #   "123".acl_permalink?                #=> nil
    #   "abc123".acl_permalink?             #=> true
    def acl_permalink?
      # Considered unfriendly if this is an instance of an unfriendly class or
      # one of its descendants.
      unfriendly_classes = [ActiveRecord::Base, Array, Hash, NilClass, Numeric,
                            Symbol, TrueClass, FalseClass]

      if unfriendly_classes.detect {|klass| self.class <= klass}
        false
      elsif respond_to?(:to_i) && to_i.to_s != to_s
        true
      end
    end

    # True if the id is definitely unfriendly, false if definitely friendly,
    # else nil.
    def unacl_permalink?
      val = acl_permalink? ; !val unless val.nil?
    end
  end
end

Object.send :include, AclPermalink::ObjectUtils
