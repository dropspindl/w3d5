require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where_section = ""
    params.each do |col, val|
      where_section += "#{col.to_s} = #{val.to_s} AND "
    end
    where_string = where_section[0..-5]

    results = DBConnection.execute(<<-SQL)
      SELECT *
      FROM #{table_name}
      WHERE #{where_string}
    SQL

    parse_all(results)
  end
end

class SQLObject
  extend Searchable
  # Mixin Searchable here...
end
