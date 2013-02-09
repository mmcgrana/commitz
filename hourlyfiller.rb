require "time"

BACKFILL_SINCE = Time.now.utc.iso8601 - 60*60*24/4
BACKFILL_UNTIL = Time.now.utc.iso8601

load "./filler.rb"
