
# -*- ruby -*-
# frozen_string_literal: true

# The top-level PG namespace.
module PG

	# cipherstash-pg *always* ships a "fat" gem with precompiled libs for each popular major.minor version
	# of Ruby that is still in use.
	major_minor = RUBY_VERSION[ /^(\d+\.\d+)/ ] or
		raise "Oops, can't extract the major/minor version from #{RUBY_VERSION.dump}"
	begin
		require "#{major_minor}/pg_ext"
	rescue => e
	        STDERR.puts "Failed to load pg_ext for #{RUBY_VERSION.dump}"
	        exit 1
	end

	class NotAllCopyDataRetrieved < PG::Error
	end
	class NotInBlockingMode < PG::Error
	end

	# Get the PG library version.
	#
	# +include_buildnum+ is no longer used and any value passed will be ignored.
	def self.version_string( include_buildnum=nil )
		"%s %s" % [ self.name, VERSION ]
	end


	### Convenience alias for PG::Connection.new.
	def self.connect( *args, &block )
		Connection.new( *args, &block )
	end


	require 'pg/exceptions'
	require 'pg/constants'
	require 'pg/coder'
	require 'pg/binary_decoder'
	require 'pg/text_encoder'
	require 'pg/text_decoder'
	require 'pg/basic_type_registry'
	require 'pg/basic_type_map_based_on_result'
	require 'pg/basic_type_map_for_queries'
	require 'pg/basic_type_map_for_results'
	require 'pg/type_map_by_column'
	require 'pg/connection'
	require 'pg/result'
	require 'pg/tuple'
	require 'pg/version'

end # module PG

