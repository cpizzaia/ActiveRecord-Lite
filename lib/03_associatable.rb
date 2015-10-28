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
    @class_name = name.to_s.camelcase.singularize if @class_name.nil?

  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @foreign_key = options[:foreign_key]
    @primary_key = options[:primary_key]
    @class_name = options[:class_name]

    @foreign_key = "#{self_class_name.to_s.downcase.singularize}_id".to_sym if @foreign_key.nil?
    @primary_key = :id if @primary_key.nil?
    @class_name = name.to_s.camelcase.singularize if @class_name.nil?
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    belongs_to_options = BelongsToOptions.new(name, options)

    define_method(name) do
      foreign_key = send(belongs_to_options.foreign_key)
      belongs_to_options.model_class.where(belongs_to_options.primary_key => foreign_key).first
    end

    assoc_options[name] = belongs_to_options
  end

  def has_many(name, options = {})
    has_many_options = HasManyOptions.new(name, self, options)

    define_method(name) do
      primary_key = send(has_many_options.primary_key)
      has_many_options.model_class.where(has_many_options.foreign_key => primary_key)
    end

    assoc_options[name] = has_many_options
  end

  def assoc_options
    @assoc_options ||= {}
  end
end

class SQLObject
  # Mixin Associatable here...
  extend Associatable
end
