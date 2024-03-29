# frozen_string_literal: false
require 'rbconfig'

tool_dir = File.dirname(File.dirname(File.realpath(__FILE__)))
src_testdir = nil

case ARGV.first
when /\A--test-target-dir=(.*?)\z/
  ARGV.shift
  src_testdir = File.realpath($1)
else
  raise "unknown runner option: #{ ARGV.first }"
end

raise "#$0: specify --test-target-dir" if !src_testdir

$LOAD_PATH << src_testdir
$LOAD_PATH.unshift "#{tool_dir}/lib"

# Get bundled gems on load path
Dir.glob("#{src_testdir}/../gems/*/*.gemspec")
  .reject {|f| f =~ /minitest|test-unit|power_assert/ }
  .map {|f| $LOAD_PATH.unshift File.join(File.dirname(f), "lib") }

require 'test/unit'

module Gem
end
class Gem::TestCase < MiniTest::Unit::TestCase
  @@project_dir = File.dirname($LOAD_PATH.last)
end

ENV["GEM_SKIP"] = ENV["GEM_HOME"] = ENV["GEM_PATH"] = "".freeze

require_relative "#{tool_dir}/lib/profile_test_all" if ENV.has_key?('RUBY_TEST_ALL_PROFILE')
require_relative "#{tool_dir}/lib/tracepointchecker"
require_relative "#{tool_dir}/lib/zombie_hunter"
require_relative "#{tool_dir}/lib/iseq_loader_checker"

if ENV['COVERAGE']
  require_relative "#{tool_dir}/test-coverage.rb"
end

begin
  exit Test::Unit::AutoRunner.run(true, src_testdir)
rescue NoMemoryError
  system("cat /proc/meminfo") if File.exist?("/proc/meminfo")
  system("ps x -opid,args,%cpu,%mem,nlwp,rss,vsz,wchan,stat,start,time,etime,blocked,caught,ignored,pending,f") if File.exist?("/bin/ps")
  raise
end
