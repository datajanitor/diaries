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
      Fetching.scrape_forms
    end

    def unpack!
      # todo
    end

    def munge!
      # todo
    end
  end

  module Fetching
    STARTING_URL = 'http://www.ucrdatatool.gov/Search/Crime/Local/JurisbyJuris.cfm'
    class << self
      def scrape_forms
        require 'open-uri'
        require 'mechanize'
        agent = Mechanize.new
        # this needed to prevent Net::HTTP::Persistent::Errors
        # https://github.com/sparklemotion/mechanize/issues/123
        agent.read_timeout = 60
        agent.idle_timeout = 0.9
        # fetch the first form
        agent.get STARTING_URL
        form_for_states = agent.page.forms[0]

        form_for_states.field_with(name: 'StateId').options.shuffle.each do |state_opt|
          state_opt.select  # this sets the state field
          puts "State: #{state_opt.text.strip} - #{state_opt.value}"
          form_for_states.submit
          # now we're on page 2
          form_for_reported_crimes = agent.page.forms[0]
          # first, let's set the field for agency
          # i.e. a. Choose an agency:
          agency_options = form_for_reported_crimes.field_with(name: 'CrimeCrossId').options
          agency_options.each do |agency_opt|
            # select the current agency
            agency_opt.select
            # prep the file
            fname = DATA_DIR.join('fetched', "#{agency_opt.value}.html")
            # skip if file already exists
            if fname.exist?
              puts "Already downloaded: #{agency_opt.text.strip}: #{agency_opt.value}"
              next
            end
            #  select all of the (4) variable groups
            form_for_reported_crimes.field_with(name: 'DataType').options.each{|o| o.select }
            # submit the form
            # because there are two submit buttons, we want to pick the correct one
            btn_submit = form_for_reported_crimes.button_with(value: 'Get Table')
            # click the submit button
            form_for_reported_crimes.click_button( btn_submit )
            # now that agent.page has the current data, write it to file as text
            open(fname, 'w'){|f| f.write agent.page.parser.to_html }
            # sleepy time
            puts "Downloaded #{agency_opt.text.strip}: #{agency_opt.value}"
            sleep 0.5 + rand(3)
          end
          # example output:
          # State: Alabama - 1
          # Downloading Alabaster Police Dept: 102
          # Downloading Albertville Police Dept: 104
          # Downloading Alexander City Police Dept: 105
          # Downloading Anniston Police Dept: 110
          # Downloading Athens Police Dept: 119
          # Downloading Atmore Police Dept: 120
          # Downloading Auburn Police Dept: 122
        end
      end
    end
  end # module Fetching
end
