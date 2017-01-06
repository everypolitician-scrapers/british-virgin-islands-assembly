#!/bin/env ruby
# encoding: utf-8

require 'nokogiri'
require 'open-uri'
require 'scraperwiki'

require 'pry'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class String
  def tidy
    self.gsub(/[[:space:]]+/, ' ').strip
  end
end

def noko_for(url)
  Nokogiri::HTML(open(url).read) rescue nil
end

def scrape_list(url)
  noko = noko_for(url)
  noko.xpath('//div[@id="page_content"]//h2/following-sibling::p/a').each do |a|
    url = URI.join(url, a.attr('href')).to_s
    fullname = a.text
    prefix, name = fullname.split('Hon. ')
    data = { 
      id: url.split('/').last,
      name: name,
      honorific_prefix: prefix + "Hon.",
      term: 3,
      source: url
    }.merge(scrape_mp(url))
    ScraperWiki.save_sqlite([:id, :term], data)
  end
end

def scrape_mp(url)
  noko = noko_for(url) or return {}

  box = noko.css('div#page_content')

  return { 
    constituency: box.xpath('.//p[strong[contains(.,"Constituency")]]/text()').text.tidy,
    party: box.xpath('.//p[strong[contains(.,"Party")]]/text()').text.tidy,
    image: URI.escape(box.css('img.imagefield/@src').text),
  }
end

scrape_list('http://www.bvi.org.uk/government/houseofassembly')
