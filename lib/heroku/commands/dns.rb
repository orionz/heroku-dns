require 'pp'

module Heroku::Command
  # manage Heroku DNS
  #
  class Dns < BaseWithApp
    # dns
    #
    # List all domains under management
    #
    def index
      domains = JSON.parse(resource("/dns").get)
      display "You have #{domains.length} domains under management."
      domains.each do |d|
        display "  #{d["zone"]["name"]}"
      end
    end

    # dns:describe DOMAIN
    #
    # describe a domain and its current records
    #
    def describe
      domain = args.shift.downcase rescue nil
      fail("Usage: heroku dns:describe DOMAIN") unless domain
      result = JSON.parse(resource("/dns/#{domain}").get)
      display result["zone"]["name"]
      result["zone"]["records"].each { |r| display sprintf("    %-16s -> %s",r["record"]["domain"], r["record"]["app"]) }
      display "Nameservers:"
      result["zone"]["servers"].each { |s| display "    #{s}" }
    end

    # dns:add DOMAIN
    #
    # Add a new domain to be managed
    #
    def add
      domain = args.shift.downcase rescue nil
      fail("Usage: heroku dns:add DOMAIN") unless domain
      begin
        result = JSON.parse(resource("/dns").post :domain => domain)
        display "Added #{domain}"
        display "Please update your dns servers to be:"
        result["zone"]["servers"].each do |server|
          display "  #{server}"
        end
      rescue RestClient::Forbidden => e
        display e.response
      end
    end

    # dns:remove DOMAIN
    #
    # Remove a domain from management.  Make sure
    # you have already set up alternate DNS servers
    # before doing this!
    #
    def remove
      domain = args.shift.downcase rescue nil
      fail("Usage: heroku dns:add DOMAIN") unless domain
      result = resource("/dns/#{domain}").delete
      display "Deleting #{domain}"
    end

    # dns:map DOMAIN APP
    #
    # Map a domain to an app
    #
    def map
      begin
        domain = args.shift.downcase rescue nil
        app = args.shift.downcase rescue nil
        fail("Usage: heroku dns:map DOMAIN APP") unless domain and app
        result = resource("/dns/#{domain}/map/#{app}").put({})
        display "Mapping #{domain} to #{app}.  It will take a few minutes for the DNS to update."
      rescue Object => e
        puts e.class.inspect
        puts "  #{e.response}"
      end
    end

    # dns:unmap DOMAIN
    #
    # Unmap a domain
    #
    def unmap
      begin
        domain = args.shift.downcase rescue nil
        fail("Usage: heroku dns:unmap DOMAIN") unless domain
        result = resource("/dns/#{domain}/map/").put({})
        display "Unmapping #{domain}."
      rescue Object => e
        puts e.class.inspect
        puts "  #{e.response}"
      end
    end

    private

    def resource(path, options={})
      uri = "https://dnsx.herokuapp.com"
      RestClient.proxy = ENV['HTTP_PROXY'] || ENV['http_proxy']
      RestClient::Resource.new "#{uri}#{path}", options.merge(:user => user, :password => password)
    end

    def user
#      Heroku::Auth.user
      ""
    end

    def password
      Heroku::Auth.password
    end

   end
end
