require 'pathname'
module DallasCrimeReports

# TODO: Workspace
# TODO: Fetching
# TODO: Unpacking
# TODO: Munging

  DATA_DIR = Pathname.new File.expand_path( '../../data-hold', __FILE__)
  def self.setup!
    %w(fetched unpacked munged).each do |dname|
      DATA_DIR.join(dname).mkpath
    end
  end

  module Fetching
    def fetch!
      require 'net/ftp'
      ftp = Net::FTP.new('66.97.146.93')
      ftp.login
      ftp.nlst('*.zip').each do |zipname|
        puts "Downloading #{zipname}"
        ftp.getbinaryfile(zipname, DATA_DIR.join('fetched', File.basename(zipname))
        sleep rand(5) + 1
      end
    end
  end

  module Unpacking
    require 'zip'
    # unzip files into unpacked
  end

  module Munging
    def munge!

    end
  end
end
