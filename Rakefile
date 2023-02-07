# -*- rake -*-

require 'rbconfig'
require 'pathname'
require 'tmpdir'
require 'rake/extensiontask'
require 'rake/clean'
require 'rspec/core/rake_task'
require 'bundler'
require 'bundler/gem_helper'

# Build directory constants
BASEDIR = Pathname( __FILE__ ).dirname
SPECDIR = BASEDIR + 'spec'
LIBDIR  = BASEDIR + 'lib'
EXTDIR  = BASEDIR + 'ext'
PKGDIR  = BASEDIR + 'pkg'
TMPDIR  = BASEDIR + 'tmp'
TESTDIR = BASEDIR + "tmp_test_*"

DLEXT   = RbConfig::CONFIG['DLEXT']
EXT     = LIBDIR + "pg_ext.#{DLEXT}"

GEMSPEC = 'cipherstash-pg.gemspec'

CLEAN.include( TESTDIR.to_s )
CLEAN.include( PKGDIR.to_s, TMPDIR.to_s )
CLEAN.include "lib/*/libpq.dll"
CLEAN.include "lib/pg_ext.*"
CLEAN.include "lib/pg/postgresql_lib_path.rb"

load 'Rakefile.cross'

Bundler::GemHelper.install_tasks
$gem_spec = Bundler.load_gemspec(GEMSPEC)

desc "Turn on warnings and debugging in the build."
task :maint do
	ENV['MAINTAINER_MODE'] = 'yes'
end

spec = Bundler.load_gemspec("cipherstash-pg.gemspec")

require "rubygems/package_task"

Gem::PackageTask.new(spec) do |pkg|
end

require "rake/extensiontask"

# Target platforms.
# The keys are the RCD platform names and the values are the Rust toolchains and Rust version that are required.
target_platforms = {
 "x86_64-linux" => { toolchain: "x86_64-unknown-linux-gnu", rust: "stable" },
 "x86_64-darwin" => { toolchain: "x86_64-apple-darwin", rust: "stable" },
 "arm64-darwin" => { toolchain: "aarch64-apple-darwin", rust: "nightly" },
 "aarch64-linux" => { toolchain: "aarch64-unknown-linux-gnu", rust: "nightly" }
}

exttask = Rake::ExtensionTask.new("cipherstash_pg", spec) do |ext|
  ext.name = "pg_ext" # TODO: Rename this when we rename+edit the lib/pg* parts of this gem.
  ext.gem_spec = $gem_spec
  ext.lib_dir = "lib"
  ext.source_pattern = "*.{rs,toml}"
  ext.cross_compile  = true
  # ext.cross_platform = %w[x86_64-linux x86_64-darwin arm64-darwin aarch64-linux]
  ext.cross_platform = %w[x86_64-linux]
end

namespace :gem do
  desc "Push all freshly-built gems to RubyGems"
  task :push do
    Rake::Task.tasks.select { |t| t.name =~ %r{^pkg/cipherstash-pg-.*\.gem} && t.already_invoked }.each do |pkgtask|
      sh "gem", "push", pkgtask.name
    end

    Rake::Task.tasks
      .select { |t| t.name =~ %r{^gem:cross:} && exttask.cross_platform.include?(t.name.split(":").last) }
      .select(&:already_invoked)
      .each do |task|
      platform = task.name.split(":").last
      sh "gem", "push", "pkg/#{spec.full_name}-#{platform}.gem"
    end
  end

  namespace :cross do
    task :prepare do
      require "rake_compiler_dock"
      sh "bundle package"
    end

    exttask.cross_platform.each do |platform|
      desc "Cross-compile all native gems in parallel"
      multitask :all => platform

      desc "Cross-compile a binary gem for #{platform}"
      task platform => :prepare do
        RakeCompilerDock.sh <<-EOT, platform: platform, image: "rbsys/rcd:#{platform}"
          set -e

					rustup default #{target_platforms[platform][:rust]}
					rustup target add #{target_platforms[platform][:toolchain]}

					(cd driver/pq-ext && RUST_TARGET=#{target_platforms[platform][:toolchain]} ./build.sh clean && ./build.sh setup && ./build.sh build)
          bundle install
          rake native:#{platform} gem RUBY_CC_VERSION=3.1.0:3.0.0:2.7.0
        EOT
      end
    end
  end
end

RSpec::Core::RakeTask.new(:spec).rspec_opts = "--profile -cfdoc"
task :test => :spec

# Use the fivefish formatter for docs generated from development checkout
require 'rdoc/task'

RDoc::Task.new( 'docs' ) do |rdoc|
	rdoc.options = $gem_spec.rdoc_options
	rdoc.rdoc_files = $gem_spec.extra_rdoc_files
	rdoc.generator = :fivefish
	rdoc.rdoc_dir = 'doc'
end

desc "Build the source gem #{$gem_spec.full_name}.gem into the pkg directory"
task :gem => :build

task :clobber do
	puts "Stop any Postmaster instances that remain after testing."
	require_relative 'spec/helpers'
	PG::TestingHelpers.stop_existing_postmasters()
end

desc "Update list of server error codes"
task :update_error_codes do
	URL_ERRORCODES_TXT = "http://git.postgresql.org/gitweb/?p=postgresql.git;a=blob_plain;f=src/backend/utils/errcodes.txt;hb=refs/tags/REL_15_0"

	ERRORCODES_TXT = "ext/errorcodes.txt"
	sh "wget #{URL_ERRORCODES_TXT.inspect} -O #{ERRORCODES_TXT.inspect} || curl #{URL_ERRORCODES_TXT.inspect} -o #{ERRORCODES_TXT.inspect}"

	ruby 'ext/errorcodes.rb', 'ext/errorcodes.txt', 'ext/errorcodes.def'
end

file 'ext/pg_errors.c' => ['ext/errorcodes.def'] do
	# trigger compilation of changed errorcodes.def
	touch 'ext/pg_errors.c'
end
