require 'pathname'
module FbiUcr
  DATA_DIR = Pathname.new File.expand_path( '../../data-hold', __FILE__)

  class << self
    def setup!
      %w(fetched unpacked munged).each do |dname|
        DATA_DIR.join(dname).mkpath
      end
    end

    def fetch!
      Fetching.scrape_form
    end

    def unpack!
      # todo
    end

    def munge!
      # todo
    end
  end

  module Fetching
    FORM_START_URL = 'http://www.ucrdatatool.gov/Search/Crime/Local/LocalCrime.cfm'
    KEY_STATE_DATAFILE = File.expand_path('../../data-source/key-state.csv', __FILE__)
    class << self
      def scrape_form
        require 'open-uri'
        require 'mechanize'

        # iterate through KEY_STATE_DATAFILE

        # iterate through each agency per state

        # collect the table HTML for each agency
      end

      private
        # form is a Mechanize::Form with values to be filled out
        # a copy of the form is made, with values filled in
        def fill_agency_form(form, agency_id)

        end
    end
  end # module Fetching

end
