require 'nokogiri'
require 'net/http'

module Crawler

  def self.call(start, stop, interval)
    (start..stop).each do |server_id|
      puts '=' * 80
      mcs = MineCraftServer.new(server_id)

      if mcs.skip?
        puts 'skip'
      else
        puts "server: #{server_id}"
        puts "name: #{mcs.name}"
        puts "country: #{mcs.country}"
        puts "ip: #{mcs.ip}"
        puts "description: #{mcs.description}"
        puts "tags: #{mcs.tags.join(', ')}"
        puts "image length: #{mcs.image.length}"
        puts "website: #{mcs.website}"

        server = Server.find_or_create_by(name: mcs.name)
        server.banner = mcs.image
        server.ip = mcs.ip
        server.description = mcs.description
        server.country = mcs.country
        server.port = 80
        server.website = mcs.website
        server.save!
        mcs.tags.each do |name|
          stc = ServersToCategories.create!(server_id: server.id, category_id: Category.find_or_create_by(name: name).id)
        end
      end

      puts '=' * 80
      sleep(interval.seconds)
    end
  end

  class MineCraftServer
    attr_accessor :response
    def initialize(server_id, host='http://minecraftservers.org')
      @response = Net::HTTP.get_response((URI("#{host}/server/#{server_id}")))
      @host = host
    end

    def skip?
      if @response.code.to_i.eql?(200)
        offline? || nobanner?
      else
        true
      end
    end

    def name
      @name ||= doc.xpath('//div[@class="section-head"]/h1').text.strip
    end

    def country
      @country ||= doc.css('span.flag')
      .tap do | span |  
        return 'US' if span.empty?
      end
      .attr('class')
      .value
      .split
      .reject { |name| name.downcase.eql?('flag') }
      .first.tap do | code | 
        return 'US' unless I18nCountrySelect::Countries::COUNTRY_CODES.include? code 
      end
    end

    def tags
      @tags ||= doc.xpath('//td[@class="tags"]/a').map(&:text).map(&:strip)
    end

    def description
      @description ||= doc.xpath('//p[@class="desc"]').text.strip
    end

    def website
      @website ||= doc.xpath('//td[text()="Website"]/following-sibling::td[1]').text.strip
    end

    def image
      file = Pathname(doc.xpath('//div[@id="info"]/img').attr('src').value)
      @image ||= CarrierWaveStringIO.new(Net::HTTP.get_response(URI("#{@host}/#{file.to_s}")).body).tap do |string_io|
        string_io.original_filename = file.basename.to_s
      end
    end

    def ip
      @ip ||= doc.xpath('//td[text()="IP"]/following-sibling::td[1]').text.strip
    end

    def offline?
      (doc.css('span.tag.offline').present? && doc.css('span.tag.online').empty?)
    end

    def nobanner?
      doc.xpath('//div[@id="info"]/img').attr('src').value.include? 'nobanner.png'
    end

    def doc
      @doc ||= Nokogiri::HTML(@response.body)
    end

  end

  class CarrierWaveStringIO < StringIO
    attr_accessor :original_filename
  end

end