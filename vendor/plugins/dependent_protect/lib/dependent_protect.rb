# DependentProtect

module DependentProtect
  def self.append_features(base)
    super
    base.extend(ClassMethods)

    ripe_class = Class.new(ActiveRecord::ActiveRecordError)
    k = ActiveRecord.const_set('ReferentialIntegrityProtectionError', ripe_class)

    base.class_eval do
      class << self
        alias_method :has_many_without_protect, :has_many
        alias_method :has_many, :has_many_with_protect
      end
    end
  end

  module ClassMethods
    # We should be aliasing configure_dependency_for_has_many but that method
    # is private so we can't. We alias has_many instead trying to be as fair
    # as we can to the original behaviour.
    def has_many_with_protect(association_id, options = {}, &extension) #:nodoc:
      reflection = create_reflection(:has_many, association_id, options, self)

      # This would break if has_many :dependent behaviour changes. One
      # solution is removing both the second when and the else branches but
      # the exception message wouldn't be exact.
      case reflection.options[:dependent]
      when :protect
        module_eval "before_destroy 'raise ActiveRecord::ReferentialIntegrityProtectionError, \"Can\\'t destroy because there\\'s at least one #{reflection.class_name} referencing this #{self.class_name}\" if self.#{reflection.name}.find(:first)'"
        options.delete(:dependent)
      when true, :destroy, :delete_all, :nullify, nil, false
        #pass
      else
        raise ArgumentError, 'The :dependent option expects either true, :destroy, :delete_all, :nullify or :protect'
      end

      has_many_without_protect(association_id, options, &extension)
    end
  end
end
