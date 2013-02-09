require "time"

BACKFILL_SINCE = Time.parse(ENV['BACKFILL_SINCE'] || raise("BACKFILL_SINCE")).utc.iso8601
BACKFILL_UNTIL = ENV['BACKFILL_UNTIL'] && Time.parse(ENV['BACKFILL_UNTIL']).utc.iso8601 || Time.now.utc.iso8601

load "./filler.rb"
