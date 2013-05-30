# Commitz

Collect git commit metadata into a Postgres query for easy analysis.

## Heroku Deploy

```console
$ heroku create
$ heroku addons:add heroku-postgresql:crane
$ heroku addons:add papertrail:ludvig
$ heroku config:add GITHUB_AUTH="<username>:<password>"
$ heroku config:add GITHUB_ORG_="heroku"
$ git push heroku master
$ heroku run bundle exec bin/migrate
$ heroku run bundle exec bin/kick
$ heroku scale web=0
$ heroku scale process=20
$ heroku logs -t

$ heroku pg:psql
> \d commits
> select count(*);
```
