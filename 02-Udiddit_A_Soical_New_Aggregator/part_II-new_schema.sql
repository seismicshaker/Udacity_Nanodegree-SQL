-- Guideline #1: here is a list of features and specifications that Udiddit needs in order its website and administrative interface:

    -- a. Allow new users to register:

CREATE TABLE "users" (
      id SERIAL PRIMARY KEY,
      username VARCHAR(25) NOT NULL,        -- 1.a.ii
      last_login TIMESTAMP,
      CONSTRAINT "unique_usernames" UNIQUE ("username"),    -- 1.a.i
      CONSTRAINT "non_null_username" CHECK (LENGTH(TRIM("username")) > 0) -- 1.a.iii
);

    -- b. Allow registered users to create new topics:

CREATE TABLE "topics" (
      id SERIAL PRIMARY KEY,
      name VARCHAR(30) NOT NULL,    -- 1.b.ii
      description VARCHAR(500),     -- 1.b.iv
      CONSTRAINT "unique_topic_names" UNIQUE ("name"),      -- 1.b.i
      CONSTRAINT "non_null_topic_name" CHECK (LENGTH(TRIM("name")) > 0)     --1.b.iii
);

    -- c. Allow registered users to create new posts on existing topics:

CREATE TABLE "posts" (
      id SERIAL PRIMARY KEY,
      title VARCHAR(100) NOT NULL,          -- 1.c.i
      created_on TIMESTAMP,
      url VARCHAR(400),
      text_content TEXT,
      topic_id INTEGER NOT NULL REFERENCES "topics" ON DELETE CASCADE,       -- 1.c.iv
      user_id INTEGER REFERENCES "users" ON DELETE SET NULL,        -- 1.c.v
      CONSTRAINT "non_null_title" CHECK (LENGTH(TRIM("title")) > 0),        -- 1.c.ii
      CONSTRAINT "url_or_text" CHECK (
            (LENGTH(TRIM("url")) > 0 AND LENGTH(TRIM("text_content")) = 0) OR
            (LENGTH(TRIM("url")) = 0 AND LENGTH(TRIM("text_content")) > 0)
      )     -- 1.c.iii
);

CREATE INDEX ON "posts"("url");

    -- d. Allow registered users to comment on existing posts:

CREATE TABLE "comments" (
      id SERIAL PRIMARY KEY,
      text_content TEXT NOT NULL,
      created_on TIMESTAMP,
      post_id INTEGER NOT NULL REFERENCES "posts" ON DELETE CASCADE,         -- 1.d.iii
      user_id INTEGER REFERENCES "users" ON DELETE SET NULL,        -- 1.d.iv
      parent_comment_id INTEGER REFERENCES "comments" ON DELETE CASCADE     -- 1.d.v
      CONSTRAINT "non_null_comment" CHECK(LENGTH(TRIM("text_content")) > 0) -- 1.d.i
);

    -- e. Make sure that a given user can only vote once on a given post:

CREATE TABLE "votes" (
      id SERIAL PRIMARY KEY,
      vote SMALLINT NOT NULL,
      post_id INTEGER NOT NULL REFERENCES "posts" ON DELETE CASCADE,         -- 1.e.iii
      user_id INTEGER REFERENCES "users" ON DELETE SET NULL,        -- 1.e.ii
      CONSTRAINT "upvote_or_downvote" CHECK("vote" = 1 OR "vote" = -1), -- 1.e.i
      CONSTRAINT "one_vote_per_user" UNIQUE (user_id, post_id)
);
