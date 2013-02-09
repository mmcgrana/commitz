require "time"

BACKFILL_SINCE = (Time.now.utc - 60*60*24/4).iso8601
BACKFILL_UNTIL = Time.now.utc.iso8601

load "./filler.rb"
