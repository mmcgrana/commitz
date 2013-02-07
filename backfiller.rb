require "time"
require "github_api"
require "sequel"
require "press"

include Press

database_url = ENV['DATABASE_URL'] || raise("DATABASE_URL")
Sequel.connect(database_url, loggers: [Press::Logger.new("commitz")])
class Commit < Sequel::Model; end

github_oauth_token = ENV['GITHUB_OAUTH_TOKEN'] || raise("GITHUB_OAUTH_TOKEN")
github = Github.new(:oauth_token => github_oauth_token)

backfill_since = Time.parse(ENV['BACKFILL_SINCE'] || raise("BACKFILL_SINCE")).utc.iso8601
backfill_until = ENV['BACKFILL_UNTIL'] && Time.parse(ENV['BACKFILL_UNTIL']).utc.iso8601 || Time.now.utc.iso8601

puts backfill_since
puts backfill_until

github_org = ENV['GITHUB_ORG'] || raise("GITHUB_ORG")
ignored_repos = YAML::load(File.open("ignored_repoz.yaml")) rescue []

pd :org => github_org
github.repos.list(:org => github_org, :type => "all").each_page do |p|
  p.each do |repo|
    unless ignored_repos.include?(repo.name)
      begin
        pd :org => github_org, :repo => repo.name
        github.repos.commits.list(github_org, repo.name, :since => backfill_since, :until => backfill_until).each_page do |q|
          q.each do |commit|
            begin
              pd :org => github_org, :repo => repo.name, :sha => commit.sha
              github.repos.commits.get(github_org, repo.name, commit.sha).tap do |c|
                # Commit.find_or_create(:repo       => repo.name,
                #                       :sha        => commit.sha,
                #                       :additions  => c.stats.additions,
                #                       :deletions  => c.stats.deletions,
                #                       :total      => c.stats.total,
                #                       :email      => c.commit.author.email,
                #                       :date       => c.commit.author['date'],
                #                       :message    => c.commit.message)
              end
            rescue => e
              pde e, :org => github_org, :repo => repo.name, :sha => commit.sha
              sleep 60
              retry
            end
          end
        end
      rescue => e
        pde e, :org => github_org, :repo => repo.name
        sleep 60
        retry
      end
    end
  end
end
