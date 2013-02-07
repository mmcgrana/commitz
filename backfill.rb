require "time"
require "github_api"
require "sequel"
require "press"

include Press

database_url = ENV['DATABASE_URL']
Sequel.connect(database_url, loggers: [Press::Logger.new("commitz")])
class Commit < Sequel::Model
end

oauth_token = ENV['GITHUB_OAUTH_TOKEN']
github = Github.new(:oauth_token => oauth_token)

def commit(data)
  puts data.inspect
end

done = %w[
ion
heroku
heartbeat
kensa
status-old
docbrown
andvari
droid
heroku-nav
heroku-docs
heroku-deploy-rails
redistogo
core
ion
shogun
darwin
addons
heroku
payments
devcenter
hermes
logplex
www
deploymaster
pgbackups
pulse
help
wolfpack
heartbeat
varnish
kensa
status-old
docbrown
support-manager
WAL-E
mitt
met
kokyaku-soldo
andvari
_waterfall
notifications
partner-tracker
mitosis
logo-dev
rendezvous
capturestack
henson
muon
configsha
droid
heroku-cedar
envmonkey
heroku-nav
Datawarehouse
heroku-docs
heroku-groups
apache.heroku.com
memcache
heroku-deploy-rails
heroku-flags
doozer-drawings
heroku-mockups
gobo
]

org = ENV['GITHUB_ORG']
since = Time.parse(ENV['BACKFILL_SINCE']).utc.iso8601
github.repos.list(:org => org, :type => "all").each_page do |p|
  p.each do |repo|
    unless done.include?(repo.name)
    begin
      github.repos.commits.list(org, repo.name, :since => since).each_page do |q|
        q.each do |commit|
          begin
            github.repos.commits.get(org, repo.name, commit.sha).tap do |c|
              Commit.find_or_create(:repo       => repo.name,
                                    :sha        => commit.sha,
                                    :additions  => c.stats.additions,
                                    :deletions  => c.stats.deletions,
                                    :total      => c.stats.total,
                                    :email      => c.commit.author.email,
                                    :date       => c.commit.author['date'],
                                    :message    => c.commit.message)
            end
          rescue => e
            pde e
            sleep 60
            retry
          end
        end
      end
    rescue => e
      pde e, :repo => repo.name
      sleep 60
      retry
    end
    end
  end
end
