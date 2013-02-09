require "github_api"
require "sequel"
require "press"

include Press

database_url = ENV['DATABASE_URL'] || raise("DATABASE_URL")
Sequel.connect(database_url, loggers: [Press::Logger.new("commitz")])
class Commit < Sequel::Model; end

github_oauth_token = ENV['GITHUB_OAUTH_TOKEN'] || raise("GITHUB_OAUTH_TOKEN")
github = Github.new(:oauth_token => github_oauth_token)

github_org = ENV['GITHUB_ORG'] || raise("GITHUB_ORG")
ignored_repos = YAML::load(File.open("ignored_repos.yaml"))[github_org] rescue []

ctx :app => "commitz", :org => github_org
pd :ignored_repos => ignored_repos.to_s

github.repos.list(:org => github_org, :type => "all").each_page do |p|
  pd :repo_remaining => p.ratelimit_remaining
  sleep 60*60/8 if p.ratelimit_remaining.to_i < 1
  p.each do |repo|
    unless ignored_repos.include?(repo.name)
      begin
        pd :repo => repo.name, :since => BACKFILL_SINCE, :until => BACKFILL_UNTIL
        github.repos.commits.list(github_org, repo.name, :since => BACKFILL_SINCE, :until => BACKFILL_UNTIL).each_page do |q|
          pd :commit_remaining => q.ratelimit_remaining
          sleep 60*60/8 if q.ratelimit_remaining.to_i < 1
          q.each do |commit|
            begin
              pd :repo => repo.name, :sha => commit.sha
              github.repos.commits.get(github_org, repo.name, commit.sha).tap do |c|
                pd :sha_remaining => c.ratelimit_remaining
                sleep 60*60/8 if c.ratelimit_remaining.to_i < 1
                Commit.find_or_create(:repo       => repo.name,
                                      :sha        => commit.sha,
                                      :additions  => c.stats.additions,
                                      :deletions  => c.stats.deletions,
                                      :total      => c.stats.total,
                                      :email      => c.commit.author.email,
                                      :date       => c.commit.author['date'],
                                      :message    => c.commit.message)
              end
            rescue Github::Error::Forbidden, Faraday::Error::ConnectionFailed, Errno::ETIMEDOUT => e
              pde e, :repo => repo.name, :sha => commit.sha
              sleep 60*60/8 if e.message.include?("403 API Rate Limit Exceeded")
              retry
            rescue => e
              pde e, :repo => repo.name, :sha => commit.sha
              raise
            end
          end
        end
      rescue Github::Error::Forbidden, Faraday::Error::ConnectionFailed, Errno::ETIMEDOUT => e
        pde e, :repo => repo.name
        sleep 60*60/8 if e.message.include?("403 API Rate Limit Exceeded")
        retry
      rescue Github::Error::ServiceError => e
        pde e, :repo => repo.name
        retry unless /409 Git Repository is empty/ =~ e.message
      rescue => e
        pde e, :repo => repo.name
        raise
      end
    end
  end
end
