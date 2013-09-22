module AclPermalink
  class Configuration

    attr_accessor :base

    attr_reader :defaults

    attr_accessor :model_class

    def initialize(model_class, values = nil)
      @model_class = model_class
      @defaults    = {}
      set values
    end

    def use(*modules)
      modules.to_a.flatten.compact.map do |object|
        mod = object.kind_of?(Module) ? object : AclPermalink.const_get(object.to_s.classify)
        model_class.send(:include, mod)
      end
    end

    def query_field
      base.to_s
    end

    private

    def set(values)
      values and values.each {|name, value| self.send "#{name}=", value}
    end
  end
end
