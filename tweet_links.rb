#!/usr/bin/env ruby
#
@description = <<EOS
Retrieves all the unique http links in the last 100 most recent tweets
usage: #{$0} <hashtag>
NOTE(S): 
1. automatically expands tiny-urls
EOS
#

require 'net/http'
require 'net/https'
require 'cgi'
require 'rubygems'
require 'json'

@hashtag = ARGV[0]
unless @hashtag
   print @description
   Process.exit
end

class TweetLinks
   def get_urls(hashtag)
      response = Net::HTTP.get(URI.parse("http://search.twitter.com/search.json?q=#{URI.escape('#'+hashtag)}&result_type=recent&rpp=100&include_entities=1"))
      response = JSON.parse(response)
      links = {}
      response && response['results'] && response['results'].each {|tweet|
         ['media', 'urls'].each {|entity_type|
            tweet['entities'][entity_type] && tweet['entities'][entity_type].each {|entity|
               link = resolve(entity['expanded_url'])
               links[link] = links[link].to_i + 1   
            }
         }
      }
      links.sort_by{|k,v| -v}.each_with_index {|entry, n|
         puts "#{n+1}. #{entry[0]}"
      }
   end

   def resolve(location)
      puts "Resolving #{location}"
      scheme = nil
      host = nil
      port = nil
      begin
         while true
	    uri = URI.parse(URI.encode(location))
	    break if uri.path.empty?
	    unless uri.relative?
	       scheme = uri.scheme 
	       host = uri.host
	       port = uri.port
	    end 
	    http = Net::HTTP.new(host, port)
	    if scheme == 'https'
	       http.use_ssl = true
	       http.verify_mode = OpenSSL::SSL::VERIFY_NONE
	    end
	    port_s = (((scheme == 'https' && port == 443) || (scheme == 'http' && port == 80))? "" : ":"+port.to_s)
	    location = "#{URI(scheme+"://"+host+port_s+uri.path)}"
	    response = http.head(uri.path)
	    break unless Net::HTTPMovedPermanently === response && location != response['Location']
	    location = response['Location']
         end 
      rescue Exception => e
         puts "Warning: Failed to resolve url"
      end
      location
   end
end

TweetLinks.new.get_urls(@hashtag)




