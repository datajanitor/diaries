require 'pathname'
module DallasCrimeReports
  DATA_DIR = Pathname.new File.expand_path( '../../data-hold', __FILE__)

  class << self
    def setup!
      %w(fetched unpacked munged).each do |dname|
        DATA_DIR.join(dname).mkpath
      end
    end

    def fetch!
      Fetching.fetch_from_ftp_site
    end

    def unpack!
      # todo
    end

    def munge!
      # todo
    end
  end


  module Fetching
    class << self
      def fetch_from_ftp_site
        require 'net/ftp'
        ftp = Net::FTP.new('66.97.146.93')
        ftp.login
        # first, download the root-level zips
        ftp.nlst('*').select{|f| f =~ /OFFENSE/ }.each do |zipname|
          fname = DATA_DIR.join('fetched', File.basename(zipname))
          if fname.exist?
            puts "#{fname} already exists"
          else
            puts "Downloading #{zipname}"
            ftp.getbinaryfile(zipname, fname)
            sleep rand 1
          end
        end
      end
    end
  end # module Fetching

  module Unpacking
    class << self
      def unpack_zips
        require 'zip'
        Dir.glob(DATA_DIR.join('fetched', '*.zip')).each do |zipname|
          puts zipname
          # TODO unzip
        end
      end
    end
  end # module Unpacking

  module Munging
    class << self

    end
  end # module Munging
end
