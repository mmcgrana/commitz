module Commitz
  module Config
    def self.env!(key)
      ENV[key] || raise("missing ENV['#{key}']")
    end

    def self.github_auth; env!("GITHUB_AUTH"); end
    def self.database_url; env!("DATABASE_URL"); end
    def self.ignored_repos; env!("IGNORED_REPOS"); end
    def self.organization; env!("ORGANIZATION"); end
  end
end
