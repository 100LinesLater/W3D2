PRAGMA foreign_keys = ON;

CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  fname TEXT NOT NULL,
  lname TEXT NOT NULL

);

CREATE TABLE questions (
  id INTEGER PRIMARY KEY, 
  title TEXT NOT NULL,
  body TEXT,
  users_id INTEGER NOT NULL,

  FOREIGN KEY (users_id) REFERENCES users(id)
);

CREATE TABLE question_follows (
  users_id INTEGER, 
  questions_id INTEGER,

  FOREIGN KEY (users_id) REFERENCES users(id),
  FOREIGN KEY (questions_id) REFERENCES questions(id)

);

CREATE TABLE replies (
  id INTEGER PRIMARY KEY,
  questions_id INTEGER NOT NULL, 
  parent_id INTEGER,
  users_id INTEGER NOT NULL,
  body TEXT,

  FOREIGN KEY (questions_id) REFERENCES questions(id),
  FOREIGN KEY (parent_id) REFERENCES replies(id),
  FOREIGN KEY (users_id) REFERENCES users(id)
);

CREATE TABLE question_likes (
  users_id INTEGER,
  questions_id INTEGER,
  likes INTEGER,

  FOREIGN KEY (users_id) REFERENCES users(id),
  FOREIGN KEY (questions_id) REFERENCES questions(id)
);

INSERT INTO users (fname, lname) 
VALUES ('Yoni', 'Hartmayer'), ('Hong', 'Gao'), ('Lance', 'Armstrong');

INSERT INTO questions (title, body, users_id)
VALUES ('title', 'body', 1), ('help', 'help me, please', 2);

INSERT INTO question_follows (users_id, questions_id)
VALUES (1, 1), (3, 2), (3, 1);

INSERT INTO replies (body, questions_id, parent_id, users_id)
VALUES ('sexy body', 1, NULL, 1), ('no, sorry lol', 2, NULL, 3), ('THATS MEAN', 2, 2, 3);

INSERT INTO question_likes (users_id, questions_id, likes) 
VALUES (1, 1, 1), (3, 2, 0), (2, 1, 1);

