require_relative '02_searchable'
require 'active_support/inflector'
require 'byebug'
# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    class_name.constantize
  end

  def table_name
    return class_name.downcase.pluralize unless class_name == "Human"
    return "humans"
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @foreign_key = options[:foreign_key]
    @primary_key = options[:primary_key]
    @class_name = options[:class_name]

    @foreign_key = "#{name.downcase}_id".to_sym if @foreign_key.nil?
    @primary_key = :id if @primary_key.nil?
    @class_name = name.camelcase.singularize if @class_name.nil?

  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    if options.empty?
      @foreign_key = "#{self_class_name.downcase}_id".to_sym
      @primary_key = :id
      @class_name = name.camelcase.singularize
    else
      @foreign_key = options[:foreign_key]
      @primary_key = options[:primary_key]
      @class_name = options[:class_name]
    end
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    belongs_to_options = BelongsToOptions.new(name.to_s, options)
    byebug
    foreign_key = belongs_to_options.send(:foreign_key)
    model_class = belongs_to_options.send(:model_class)
    model_class.where(primary_key: foreign_key)
    # define_method(name) do
    #   foreign_key = options.send(:foreign_key)
    #   model_class = options.send(:model_class)
    #   model_class.where(primary_key: foreign_key)
    # end
  end

  def has_many(name, options = {})
    # ...
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
  end
end

class SQLObject
  # Mixin Associatable here...
  extend Associatable
end
