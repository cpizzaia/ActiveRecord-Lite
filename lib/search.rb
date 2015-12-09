require_relative 'db_connection'
require_relative 'sql_object'


module Searchable
  def where(params)
    keys = params.keys
    joined_keys = keys.join(" = ? AND ") + "= ?"
    values = params.values
    results = DBConnection.execute(<<-SQL, *values)
      SELECT
        *
      FROM
        "#{table_name}"
      WHERE
        #{joined_keys}
    SQL
    return [] if results.empty?
    parse_all(results)
  end
end

class SQLObject
  extend Searchable
end
