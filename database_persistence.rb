require 'dotenv/load'
require 'pg'

class DatabasePersistence
  def initialize(logger)
    @db = PG.connect(dbname: 'todos', password: ENV['DB_PASSWORD'])
    @logger = logger
  end

  def find_list(id)
    sql = 'SELECT * FROM lists WHERE id = $1;'
    result = query(sql, id)
    tuple = result.first
    { id: tuple['id'], name: tuple['name'], todos: find_todos_for_list(tuple['id']) }
  end

  def all_lists
    sql = 'SELECT * FROM lists;'
    result = query(sql)

    result.map do |tuple|
      { id: tuple['id'], name: tuple['name'], todos: find_todos_for_list(tuple['id']) }
    end
  end

  def create_new_list(name)
    query 'INSERT INTO lists (name) VALUES ($1);', name
  end

  def delete_list(id)
    query 'DELETE FROM todos WHERE list_id = $1;', id
    query 'DELETE FROM lists WHERE id = $1;', id
  end

  def delete_todo_from_list(list_id, todo_id)
    sql = 'DELETE FROM todos WHERE list_id = $1 AND id = $2;'
    query sql, list_id, todo_id
  end

  def update_list_name(id, name)
    query 'UPDATE lists SET name = $1 WHERE id = $2;', name, id
  end

  def create_new_todo(list_id, todo_name)
    sql = 'INSERT INTO todos (name, list_id) VALUES ($1, $2);'
    query sql, todo_name, list_id
  end

  def update_todo_status(list_id, todo_id, new_status)
    sql = 'UPDATE todos SET completed = $1 WHERE list_id = $2 AND id = $3;'
    query sql, new_status, list_id, todo_id
  end

  def mark_all_todos_as_completed(list_id)
    query 'UPDATE todos SET completed = true WHERE list_id = $1;', list_id
  end

  private

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end

  def to_bool(str)
    case str.downcase
    when 'f' then false
    when 'false' then false
    when 't' then true
    when 'true' then true
    else nil
    end
  end

  def find_todos_for_list(list_id)
    sql = 'SELECT * FROM todos WHERE list_id = $1;'
    result = query(sql, list_id)
    result.map do |tuple|
      { id: tuple['id'], name: tuple['name'], completed: to_bool(tuple['completed']) }
    end
  end
end
