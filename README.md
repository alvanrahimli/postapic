# Post a Pic!
Feed for pictures posted by homies
***
Have you ever wanted to have a small, cozy place where only your friends can submit a random picture, and everyone can see it? 

Well, I have. So, we created postapic!

With postapic, predefined users can submit a photo and see what others have shared. And that is all. No likes, upvotes, comments, notifications, etc.

**Note: Will probably rewrite in C#**

# Installation
- Clone the repository
- Create directory `db` (docker compose will use this directory as volume, to make persistent database)
- Copy `users_sample.json` to `db/users_sample.json` (And fill accounts for every friend (define `user_id` too, incrementaly))
- run `docker compose up -d` ([docker-compose.yml](https://github.com/alvanrahimli/postapic/blob/master/docker-compose.yml))
