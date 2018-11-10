require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    @columns ||= DBConnection.execute2(<<-SQL)
      SELECT * FROM #{self.table_name} WHERE 1 = 0
    SQL
    @columns[0].map(&:to_sym)
  end

  def self.finalize!
    self.columns.each do |col|
      define_method(col) do
        self.attributes[col]
      end

      define_method("#{col}=") do |value|
        self.attributes[col]= value
      end
    end
  end

  def self.table_name=(table_name)
     @table_name = table_name
  end

  def self.table_name
    @table_name || name.downcase.pluralize
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT *
      FROM #{self.table_name}
    SQL

    parse_all(results)
  end

  def self.parse_all(results)
    results.map do |result|
      self.new(result)
    end
  end

  def self.find(id)
    results = DBConnection.execute(<<-SQL, id)
      SELECT *
      FROM #{self.table_name}
      WHERE id = ?
    SQL

    parse_all(results).first
  end

  def initialize(params = {})
    params.each do |atr, value|
      atr = atr.to_sym
      if self.class.columns.include?(atr)
        self.send("#{atr}=", value)
      else
        raise "unknown attribute '#{atr}'"
      end
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map { |attr| self.send(attr) }
  end

  def insert
    cols = self.class.columns.drop(1)
    col_names= cols.map(&:to_s).join(", ")
    question_marks = Array.new(cols.length, "?").join(", ")

    whateverthisis = DBConnection.execute(<<-SQL, *attribute_values.drop(1))
      INSERT INTO #{self.class.table_name} (#{col_names})
      VALUES (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    cols = self.class.columns.join(" = ?,")

    whateverthisis = DBConnection.execute(<<-SQL, *attribute_values, id)
      UPDATE #{self.class.table_name}
      SET #{cols} = ?
      WHERE id = ?
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def save
    if id.nil?
      insert
    else
      update
    end
  end

end
