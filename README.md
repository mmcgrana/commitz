# Commitz

Collect git commit metadata into a Postgres query for easy analysis.

## Heroku Deploy

```console
$ heroku create
$ heroku addons:add heroku-postgresql:crane
$ heroku config:add GITHUB_AUTH="<username>:<password>"
$ heroku config:add GITHUB_ORG_="heroku"
$ heroku config:add IGNORED_REPOS="otp,redistogo"
$ git push heroku master
$ heroku run bundle exec bin/migrate
$ heroku scale run=1

$ heroku pg:psql
> \d commits
> select * from commits limit 5;
```
