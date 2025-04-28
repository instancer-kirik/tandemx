\copy (SELECT * FROM phrases) TO '/tmp/phrases.csv' WITH (FORMAT CSV, HEADER);
\copy (SELECT * FROM users) TO '/tmp/users.csv' WITH (FORMAT CSV, HEADER);
\copy (SELECT * FROM hashes) TO '/tmp/hashes.csv' WITH (FORMAT CSV, HEADER);
\copy (SELECT * FROM posts) TO '/tmp/posts.csv' WITH (FORMAT CSV, HEADER); 