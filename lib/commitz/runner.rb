require "scrolls"
require "github_api"
require "grit"
require "language_sniffer"

require "./lib/commitz/config"

module Commitz
  module Runner
    def self.start
      github = Github.new(:basic_auth => Config.github_auth, :auto_pagination => true)
      repo_names = github.repos.list(:org => Config.organization).map { |r| r.name }
      repo_name = repo_names.first
      puts(repo_name)
    end
  end
end
