require "github_api"
require "grit"
require "language_sniffer"
require "rush"
require "scrolls"
require "sequel"

require "./lib/commitz/config"

module Commitz
  Sequel.connect(Config.database_url)

  class Commit < Sequel::Model
  end

  module Runner
    def self.get_repo_names
      Scrolls.log(:key => "get_repo_names") do
        github = Github.new(:basic_auth => Config.github_auth, :auto_pagination => true)
        github.repos.list(:org => Config.github_org).map { |r| r.name }
      end
    end

    def self.local_repo_path(repo_name)
      "/tmp/commitz/repos/#{repo_name}"
    end

    def self.get_repo(repo_name)
      Scrolls.log(:key => "get_repo", :repo_name => repo_name) do
        Rush.bash("mkdir -p #{File.dirname(local_repo_path(repo_name))}")
        Rush.bash("rm -rf #{local_repo_path(repo_name)}")
        Rush.bash("git clone https://#{Config.github_auth}@github.com/#{Config.github_org}/#{repo_name} #{local_repo_path(repo_name)}")
      end
    end

    def self.get_commits(repo_name)
      Scrolls.log(:key => "get_commits", :repo_name => repo_name) do
        Dir.chdir(local_repo_path(repo_name)) do
          Rush.bash("git reset --hard origin/master")
          repo = Grit::Repo.new(".")
          commits = Grit::Commit.find_all(repo, nil)
          commits[0..10].map do |commit|
            Scrolls.log(:key => "get_commit", :repo_name => repo_name, :sha => commit.sha) do
              Rush.bash("git reset --hard #{commit.sha}")
              commit_stats = commit.stats
              commit_diffs = commit_stats.files.map do |filename, _, _, diffs|
              language =
                if ["Procfile", "CHANGELOG", "LICENSE", "License", "REST", "dist/resources/deb/control"].include?(File.basename(filename))
                  "Text"
                elsif filename =~ /Gemfile(\.lock)?|\.gem|spec\.opts$/
                  "Ruby"
                elsif filename =~ /\.iss$/
                  "Windows"
                elsif filename =~ /\.pem$/
                  "Pem"
                elsif filename =~ /\.gitignore$/
                  "Git"
                elsif filename =~ /\/deb\//
                  "Deb"
                else
                  begin
                    sniffed = LanguageSniffer.detect(filename).language
                    if !sniffed
                      Scrolls.log(:key => "missed_sniff", :repo_name => repo_name, :sha => commit.sha, :filename => filename)
                    end
                    sniffed && sniffed.name
                  rescue
                    Scrolls.log(:key => "missing_file", :repo_name => repo_name, :sha => commit.sha, :filename => filename)
                    nil
                  end
                end
                [language, diffs]
              end
              commit_total_diffs = commit_diffs.inject({}) do |accum, (language, diffs)|
                accum[language] ||= 0
                accum[language] += diffs
                accum
              end
              commit_language = commit_diffs.empty? ? nil : commit_total_diffs.sort_by { |langauge, diffs| -diffs }[0][0]
              {
                :sha => commit.sha,
                :additions => commit_stats.additions,
                :deletions => commit_stats.deletions,
                :email => commit.author.email,
                :date => commit.date,
                :message => commit.message,
                :language => commit_language
              }
            end
          end
        end
      end
    end

    def self.persist_commits(repo_name, commits)
      Scrolls.log(:key => "persist_commits", :repo_name => repo_name) do
        commits.each do |commit|
          Scrolls.log(:key => "persist_commit", :repo_name => repo_name, :sha => commit[:sha]) do
            Commit.create(
              :repo      => repo_name,
              :sha       => commit[:sha],
              :additions => commit[:additions],
              :deletions => commit[:deletions],
              :email     => commit[:email],
              :date      => commit[:date],
              :message   => commit[:message],
              :language  => commit[:language]
            )
          end
        end
      end
    end

    def self.start
      repo_names = get_repo_names
      repo_name = repo_names.first
      repo_name = "heroku"
      get_repo(repo_name)
      commits = get_commits(repo_name)
      persist_commits(repo_name, commits)
    end
  end
end
