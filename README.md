# Commitz

Collect git commit metadata into a Postgres query for easy analysis.

## Heroku Deploy

```console
$ heroku create
$ heroku addons:add heroku-postgresql:crane
$ heroku config:add ORGANIZATION="heroku"
$ heroku config:add IGNORED_REPOS="otp,redistogo"
$ git push heroku master
$ heroku run bundle exec bin/migrate
$ heroku scale runner=1

$ heroku pg:psql
> \x
> select * from commits limit 5;
```
