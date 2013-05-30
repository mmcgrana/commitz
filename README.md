# Commitz

Collect git commit metadata into a Postgres query for easy analysis.

## Usage

Deploy the app to Heroku:

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
```

Watch the processing progress:

```console
$ heroku pg:psql
> select count(*) from queue_classic_jobs;
```

Once processing is done, analyze the resulting commits data:

```console
$ heroku pg:psql
> select count(*) from commits;
```

You may want to prune duplicate commits from forked / copied repos:

```console
$ heroku pg:psql
> delete from commits where exists(select * from commits c where c.sha = commits.sha and commits.id > c.id);
```
