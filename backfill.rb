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

org = ENV['GITHUB_ORG']
since = Time.parse(ENV['BACKFILL_SINCE']).utc.iso8601
github.repos.list(:org => org, :type => "all").each_page do |p|
  p.each do |repo|
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
      pde e
      sleep 60
      retry
    end
  end
end
