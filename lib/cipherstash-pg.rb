require_relative './pg'

module CipherStash
  module PG
    DB_EXT_DIR = File.join(__dir__, '../vendor/database-extensions')

    def self.install_script
      File.read(File.join(DB_EXT_DIR, "install.sql"))
    end

    def self.uninstall_script
      File.read(File.join(DB_EXT_DIR, "uninstall.sql"))
    end
  end
end
