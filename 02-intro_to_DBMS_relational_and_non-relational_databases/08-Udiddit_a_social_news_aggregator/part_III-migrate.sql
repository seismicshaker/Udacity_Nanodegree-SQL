-- Migrate Data

  -- a. Users Table

INSERT INTO "users"("username")
      SELECT DISTINCT username FROM bad_posts
      UNION
      SELECT DISTINCT username FROM bad_comments
      UNION
      SELECT DISTINCT regexp_split_to_table(upvotes, ',') FROM bad_posts
      UNION
      SELECT DISTINCT regexp_split_to_table(downvotes, ',') FROM bad_posts;


  -- b. Topics Table

INSERT INTO "topics"("name")
      SELECT DISTINCT topic FROM bad_posts;

   -- c. Posts Table

INSERT INTO "posts" (
      "user_id",
      "topic_id",
      "title",
      "url",
      "text_content"
)

SELECT users.id, topics.id, LEFT(bad_posts.title, 100),
       bad_posts.url, bad_posts.text_content FROM bad_posts
      JOIN users ON bad_posts.username = users.username
      JOIN topics ON bad_posts.topic = topics.name;

   -- d. Comments Table

INSERT INTO "comments" (
      "post_id",
      "user_id",
      "text_content"
)

SELECT posts.id, users.id, bad_comments.text_content FROM bad_comments
      JOIN users ON bad_comments.username = users.username
      JOIN posts ON posts.id = bad_comments.post_id;

   -- e.i Upvotes

INSERT INTO "votes" (
      "post_id",
      "user_id",
      "vote"
)

SELECT "upvoter"."id", "users"."id", 1 AS "upvote"
      FROM( SELECT "id", REGEXP_SPLIT_TO_TABLE("upvotes", ',') AS "upvotes"
              FROM "bad_posts") AS "upvoter"
      JOIN "users"
      ON "upvoter"."upvotes" = "users"."username";

   -- e.ii Downvotes

INSERT INTO "votes" (
      "post_id",
      "user_id",
      "vote"
)

SELECT "downvoter"."id", "users"."id", -1 AS "downvote"
      FROM ( SELECT "id", REGEXP_SPLIT_TO_TABLE("downvotes", ',') AS "downvotes"
            FROM "bad_posts") AS "downvoter"
      JOIN "users"
      ON "downvoter"."downvotes" = "users"."username";
