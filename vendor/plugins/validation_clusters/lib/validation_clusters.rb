module ValidationClusters
  class << self
    def included(base)
      base.extend(ClassMethods)
    end
    
    module ClassMethods
      def validates_field(name, &block)
        cluster = ValidationClustersBlockMethodFaker.new
        cluster.field = name
        cluster.klass = self
        yield cluster
      end
    end
  end
  
  class ValidationClustersBlockMethodFaker
    attr_accessor :field
    attr_accessor :klass
    
    def method_missing(name, args = {})
      validation_method = "validates_#{name}_of"
      klass.send(validation_method.to_sym, field, args)
    end
  end
end