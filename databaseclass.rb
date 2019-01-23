require "sqlite3"
require "singleton"

class QuestionsDatabase < SQLite3::Database
  include Singleton

    def initialize()
      super('questions.db')
      self.type_translation = true
      self.results_as_hash = true
    end

end

# class ModelBase
#   tables_hash = {
#     Users => "users",
#     Questions => "questions",
#     Replies => "replies",
#     QuestionFollows => "question_follows",
#     QuestionLikes => "question_likes"
#   }

#   def self.find_by_id(id)
#     data = QuestionsDatabase.instance.execute(<<-SQL, id)
#     SELECT
#       *
#     FROM
#       tables_hash[self.class]
#     WHERE
#       id = ?
#     SQL
#     self.class.new(data.first)
#   end

#   def initialize 

#   end

# end

class Users
  attr_accessor :fname, :lname

  def self.find_by_id(id)
    data = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      users
    WHERE
      id = ?
    SQL
    Users.new(data.first)
  end

  def self.find_by_name(fname, lname)
    data = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
    SELECT
      *
    FROM
      users
    WHERE
      fname = ? AND lname = ?
    SQL
    data.map {|item| Users.new(item)}
  end

  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end

  def save
    unless @id
      QuestionsDatabase.instance.execute(<<-SQL, @fname, @lname)
        INSERT INTO
          users (fname, lname)
        VALUES
          (?, ?)
      SQL
      @id = QuestionsDatabase.instance.last_insert_row_id

    else
      QuestionsDatabase.instance.execute(<<-SQL, @fname, @lname, @id)
        UPDATE
          users
        SET
          fname = ?, lname = ?
        WHERE
          id = ?
      SQL
    end
  end

  def authored_questions
    Questions.find_by_author_id(@id)
  end

  def authored_replies
    Replies.find_by_user_id(@id)
  end

  def followed_questions
    QuestionFollows.followed_questions_for_user_id(@id)
  end

  def liked_questions
    QuestionLikes.liked_questions_for_user_id(@id)
  end

  def average_karma
     data = QuestionsDatabase.instance.execute(<<-SQL, @id)
    SELECT
      CAST(SUM(question_likes.questions_id) AS FLOAT) / COUNT(DISTINCT question_likes.questions_id) as result
    FROM
      users
    JOIN
      question_likes
    ON
      users.id = question_likes.users_id
    JOIN 
      questions
    ON
      questions.id = question_likes.questions_id
    WHERE
      questions.users_id = ?
    GROUP BY
      question_likes.questions_id
        
    SQL
    data.first['result']
  end
end


class Questions
  attr_accessor :title, :body, :users_id

  def self.find_by_id(id)
    data = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      questions
    WHERE
      id = ?
    SQL
    Questions.new(data.first)
  end

  def self.find_by_author_id(users_id)
    data = QuestionsDatabase.instance.execute(<<-SQL, users_id)
    SELECT
      *
    FROM
      questions
    WHERE
      users_id = ?
    SQL
    data.map {|enum| Questions.new(enum)}
  end

  def self.most_followed(n)
    QuestionFollows.most_followed_questions(n)
  end

   def self.most_liked(n)
      data = QuestionsDatabase.instance.execute(<<-SQL, n)
    SELECT
      questions.*
    FROM
      questions
    JOIN
      question_likes
    ON
      questions.id = question_likes.questions_id
    GROUP BY
      question_likes.questions_id
    HAVING
      likes = 1
    ORDER BY
     count(likes)
    LIMIT ?
    SQL
    data.map {|item| Questions.new(item)}
  end

  def initialize(options)
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @users_id = options['users_id']
  end

  def save
    unless @id
      QuestionsDatabase.instance.execute(<<-SQL, @title, @body, @users_id)
        INSERT INTO
          questions (title, body, users_id)
        VALUES
          (?, ?, ?)
      SQL
      @id = QuestionsDatabase.instance.last_insert_row_id

    else
      QuestionsDatabase.instance.execute(<<-SQL, @title, @body, @users_id, @id)
        UPDATE
          questions
        SET
          title = ?, body = ?, users_id = ?
        WHERE
          id = ?
      SQL
    end
  end

  def author
    Users.find_by_question_id(@id)
  end

  def replies
    Replies.find_by_question_id(@id)
  end

  def followers
    QuestionFollows.followers_for_question_id(@id)
  end

  def likers 
    QuestionLikes.likers_for_question_id(@id)
  end

  def num_likes
    QuestionLikes.num_likes_for_question_id(@id)
  end
end

class QuestionFollows
  attr_accessor :users_id, :questions_id

  def self.followers_for_question_id(questions_id)
    data = QuestionsDatabase.instance.execute(<<-SQL, questions_id)
    SELECT
     users.*
    FROM
      question_follows
      JOIN users
        ON users_id = users.id
    WHERE
      questions_id = ?
    SQL
     data.map {|item| Users.new(item)}
  end

  def self.followed_questions_for_user_id(users_id)
    data = QuestionsDatabase.instance.execute(<<-SQL, users_id)
    SELECT
      questions.*
    FROM
      questions
      JOIN question_follows
        ON questions_id = questions.id
    WHERE
      question_follows.users_id = ?
    SQL
     data.map {|item| Questions.new(item)}
  end

  def self.most_followed_questions(n)
    data = QuestionsDatabase.instance.execute(<<-SQL, n)
    SELECT
      questions.*
    FROM
      questions
    JOIN question_follows
      ON questions_id = questions.id
    GROUP BY 
      questions.title
    ORDER BY
      COUNT(question_follows.users_id) DESC
    LIMIT ?
    SQL
    data.map {|item| Questions.new(item)}
  end

  def initialize(options)
    @users_id = options['users_id']
    @questions_id = options['questions_id']
  end
end

class Replies
  attr_accessor :users_id, :questions_id, :parent_id, :body

  def self.find_by_id(id)
    data = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      replies
    WHERE
      id = ?
    SQL
    Replies.new(data.first)
  end

  def self.find_by_user_id(users_id)
    data = QuestionsDatabase.instance.execute(<<-SQL, users_id)
    SELECT
      *
    FROM
      replies
    WHERE
      users_id = ?
    SQL
    data.map {|item| Replies.new(item)}
  end

  def self.find_by_question_id(questions_id)
    data = QuestionsDatabase.instance.execute(<<-SQL, questions_id)
    SELECT
      *
    FROM
      replies
    WHERE
      questions_id = ?
    SQL
    data.map {|item| Replies.new(item)}
  end

  def self.find_by_parent_id(parent_id)
    data = QuestionsDatabase.instance.execute(<<-SQL, parent_id)
    SELECT
      *
    FROM
      replies
    WHERE
      parent_id = ?
    SQL
    data.map {|item| Replies.new(item)}
  end

  def initialize(options)
    @id = options['id']
    @body = options['body']
    @questions_id = options['questions_id']
    @users_id = options['users_id']
    @parent_id = options['parent_id']
  end

  def save
    unless @id
      QuestionsDatabase.instance.execute(<<-SQL, @title, @body, @questions_id, @parent_id, @users_id)
        INSERT INTO
          replies (title, body, questions_id, parent_id, users_id)
        VALUES
          (?, ?, ?, ?, ?)
      SQL
      @id = QuestionsDatabase.instance.last_insert_row_id

    else
      QuestionsDatabase.instance.execute(<<-SQL, @title, @body, @questions_id, @parent_id, @users_id, @id)
        UPDATE
          replies
        SET
          title = ?, body = ?, questions_id = ?, parent_id = ?, users_id = ?
        WHERE
          id = ?
      SQL
    end
  end

  def author 
    Users.find_by_id(@users_id)
  end

  def question 
    Questions.find_by_id(@questions_id)
  end

  def parent_reply
    Replies.find_by_id(@parent_id)
  end

  def child_replies
    Replies.find_by_parent_id(@id)
  end
end

class QuestionLikes
  attr_accessor :users_id, :questions_id, :likes

  def self.likers_for_question_id(questions_id)
    data = QuestionsDatabase.instance.execute(<<-SQL, questions_id)
    SELECT
      users.*
    FROM
      users
    JOIN
      question_likes
    ON
      users.id = question_likes.users_id
    WHERE
      questions_id = ?
      AND likes = 1
    SQL
    data.map {|item| Users.new(item)}
  end

  def self.num_likes_for_question_id(questions_id)
    data = QuestionsDatabase.instance.execute(<<-SQL, questions_id)
    SELECT
      COUNT(fname)
    FROM
      users
    JOIN
      question_likes
    ON
      users.id = question_likes.users_id
    WHERE
      questions_id = ?
      AND likes = 1
    SQL
    data.first["COUNT(fname)"]
  end

  def self.liked_questions_for_user_id(users_id)
    data = QuestionsDatabase.instance.execute(<<-SQL, users_id)
    SELECT
      questions.*
    FROM
      questions
    JOIN
      question_likes
    ON
      questions.id = question_likes.questions_id
    WHERE
      question_likes.users_id = ?
    AND likes = 1
    SQL
    data.map {|item| Questions.new(item)}
  end

  def self.most_liked_questions(n)
    data = QuestionsDatabase.instance.execute(<<-SQL, n)
    SELECT
      questions.*
    FROM
      questions
    JOIN
      question_likes
    ON
      questions.id = question_likes.questions_id
    GROUP BY
      question_likes.questions_id
    HAVING
      likes = 1
    ORDER BY
     count(likes)
    LIMIT ?
    SQL
    data.map {|item| Questions.new(item)}
  end


  def initialize(options)
    @questions_id = options['questions_id']
    @likes = options['likes']
    @users_id = options['users_id']
  end


end