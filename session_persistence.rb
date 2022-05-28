# frozen_string_literal: true

# Saves user list and todo data in the session
class SessionPersistence
  def initialize(session)
    @session = session
    @session[:lists] ||= []
  end

  def find_list(list_id)
    session[:lists].find { |list| list[:id] == list_id }
  end

  def all_lists
    session[:lists]
  end

  def new_list(name)
    all_lists << { id: next_id(all_lists), name: name, todos: [] }
  end

  def rename_list(list_id, new_name)
    list = find_list(list_id)
    list[:name] = new_name
  end

  def delete_list(list_id)
    delete_item(all_lists, list_id)
  end

  def add_todo(list_id, text)
    list = find_list(list_id)
    list[:todos] << { id: next_id(list[:todos]), name: text, completed: false }
  end

  def delete_todo(list_id, todo_id)
    list = find_list(list_id)
    delete_item(list[:todos], todo_id)
  end

  def set_todo_status(list_id, todo_id, status)
    list = find_list(list_id)
    todo = find_todo(list, todo_id)
    todo[:completed] = status
  end

  def complete_all_todos(list_id)
    find_list(list_id)[:todos].each { |todo| todo[:completed] = true }
  end

  private

  attr_accessor :session

  def next_id(elements)
    max = elements.map { |todo| todo[:id] }.max || 0
    max + 1
  end

  def delete_item(collection, item_id)
    collection.reject! { |item| item[:id] == item_id }
  end

  def find_todo(list, todo_id)
    list[:todos].find { |todo| todo[:id] == todo_id }
  end
end
