# frozen_string_literal: true

require 'pg'

# Provides an API for communication between the todos app and PostgreSQL
class DatabasePersistence
  def initialize(logger)
    @db = if Sinatra::Base.production?
            PG.connect(ENV['DATABASE_URL'])
          else
            PG.connect(dbname: 'todos')
          end
    @logger = logger
  end

  # Return a list as a hash
  def find_list(list_id)
    sql = 'SELECT * FROM lists WHERE id = $1'
    result = query(sql, list_id)
    tuple = result.first

    format_list(tuple)
  end

  # Return an array of all lists
  def all_lists
    sql = 'SELECT * FROM lists'
    result = query(sql)

    result.map { |tuple| format_list(tuple) }
  end

  # Add a new list to the database `lists` table
  def new_list(name)
    sql = 'INSERT INTO lists (name) VALUES ($1)'
    query(sql, name)
  end

  # Update the name of a list in the database `lists` table
  def rename_list(list_id, new_name)
    sql = 'UPDATE lists SET name = $1 WHERE id = $2'
    query(sql, new_name, list_id)
  end

  # Delete a list form the database `lists` table
  def delete_list(list_id)
    query('DELETE FROM todos WHERE list_id = $1', list_id)
    query('DELETE FROM lists WHERE id = $1', list_id)
  end

  # Add a todo to the database `todos` table
  def add_todo(list_id, new_name)
    sql = 'INSERT INTO todos (list_id, name) VALUES ($1, $2)'
    query(sql, list_id, new_name)
  end

  def delete_todo(list_id, todo_id)
    sql = 'DELETE FROM todos WHERE list_id = $1 AND id = $2'
    query(sql, list_id, todo_id)
  end

  def set_todo_status(list_id, todo_id, completion_status)
    sql = 'UPDATE todos SET completed = $1 WHERE list_id = $2 AND id = $3'
    query(sql, completion_status, list_id, todo_id)
  end

  def complete_all_todos(list_id)
    sql = 'UPDATE todos SET completed = true WHERE list_id = $1'
    query(sql, list_id)
  end

  def disconnect
    @db.close
  end

  private

  attr_accessor :session

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end

  def convert_to_boolean(string)
    case string
    when 't' then true
    when 'f' then false
    else          raise ArgumentError, 'Argument must be "true" or "false"'
    end
  end

  def get_todos(list_id)
    sql = 'SELECT * FROM todos WHERE list_id = $1;'
    todos_result = query(sql, list_id)

    todos_result.map do |tuple|
      completed = convert_to_boolean(tuple['completed'])

      { id: tuple['id'].to_i, name: tuple['name'], completed: completed }
    end
  end

  def format_list(tuple)
    list_id = tuple['id'].to_i

    { id: list_id, name: tuple['name'], todos: get_todos(list_id) }
  end

  def delete_item(collection, item_id)
    # collection.reject! { |item| item[:id] == item_id }
  end

  def find_todo(list, todo_id)
    # list[:todos].find { |todo| todo[:id] == todo_id }
  end
end
