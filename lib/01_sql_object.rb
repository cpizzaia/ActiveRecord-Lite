require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject

  def self.columns
    result = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        "#{table_name}"
    SQL
    method_array = result.first.map do |heading|
      heading.to_sym
    end
  end

  def self.finalize!
    table_name
    method_array = columns
    method_array.each do |method|
      self.send(:define_method, method) do
        attributes
        @attributes[method]
      end
      self.send(:define_method, "#{method}=".to_sym) do |arg|
        attributes
        @attributes[method] = arg
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= "#{self.name.downcase}s"
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        "#{table_name}"
    SQL

    parse_all(results)
  end

  def self.parse_all(results)
    results.map do |params|
      self.new(params)
    end
  end

  def self.find(id)
    result = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        "#{table_name}"
      WHERE
        id = ?
    SQL
    return nil if result.empty?
    parse_all(result).first
  end

  def initialize(params = {})
    column_array = self.class.columns
    params.each do |attr_name, value|
      raise "unknown attribute '#{attr_name}'" unless column_array.include?(attr_name.to_sym)
      attr_name = "#{attr_name}=".to_sym
      self.send(attr_name, value)
    end

  end

  def attributes
    @attributes ||= Hash.new
  end

  def attribute_values
    attributes.values
  end

  def insert
    headers = self.class.columns[1..-1]
    values = attribute_values
    count = headers.length
    joined_headers = headers.join(" ,")
    joined_headers = "(#{joined_headers})"
    q_array = (["?"] * count).join(" ,")
    q_array = "(#{q_array})"
    DBConnection.execute(<<-SQL, *values)
      INSERT INTO
        "#{self.class.table_name}" #{joined_headers}
      VALUES
        #{q_array}
    SQL
    self.id = self.class.all.length
  end

  def update
    headers = self.class.columns[1..-1]
    joined_headers = headers.join(" = ?, ") + "= ?"
    values = attribute_values[1..-1]
    DBConnection.execute(<<-SQL, *values, id)
      UPDATE
        "#{self.class.table_name}"
      SET
        #{joined_headers}
      WHERE
        id = ?
    SQL
  end

  def save
    id.nil? ? insert : update
  end
end
