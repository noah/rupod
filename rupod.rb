#!/usr/bin/env ruby
#
# rupod : selectively delete albums or artists (uses gnupod)
#       (c) 2010 Noah K. Tilton
#
# Released under the terms of the MIT license:
#       http://www.opensource.org/licenses/mit-license.php

require 'pp'

class String
  def in_path? 
    return ! /no #{self} in/.match(`which #{self} 2>&1`)
  end

  def mounted?
    return `mount|grep #{Gnupod::IPOD}|wc -l`.to_i > 0
  end
end

class Array
  def / len
    a = []
    each_with_index do |x,i|
      a << [] if i % len == 0
      a.last << x
    end
    a
  end
end

module Gnupod

  IPOD='/mnt/ipod'
  GNUPOD_SEARCH_SCRIPT='gnupod_search.pl --view=la'

  class Gnupod
    include Enumerable

    def initialize
      self.sane?
      @data = {'artist' => [], 'album' => []}
      @view = nil # override below
      self.read
    end

    def [](n)
      @data[n]
    end

    def each
      @data[@view].each { |i| yield i }
    end

    def each_index
      @data[@view].each_index { |i| yield i }
    end

    def sane?
      if ! GNUPOD_SEARCH_SCRIPT.in_path?
        puts "#{GNUPOD_SEARCH_SCRIPT} not found in path, exiting . . ." 
        exit -1
      end

      if ! IPOD.mounted?
        puts "#{IPOD} not mounted, exiting . . .\nN.B.:  rupod expects your mountpoint to be `#{IPOD}'"
        exit -1
      end
    end
    
    def read
      aa = `#{GNUPOD_SEARCH_SCRIPT}`.split(/\n/).collect {|e| 
        e.split('|').collect{|e| e.strip}
      }.reject{|e| e.join(' ') =~ /ALBUM|ARTIST|gnupod_search.pl|===/}.sort.uniq
      aa.collect{|el| el[1]}.sort.uniq.each_with_index do |el,i|
        @data['artist'][i] = {
          'artist' => el,
          'status' => RupodModule::KEEP,
          'index' => i
        }
      end
      aa.collect{|el| el[0]}.sort.uniq.each_with_index do |el,i|
        @data['album'][i] = {
          'album' => el,
          'status' => RupodModule::KEEP,
          'index' => i
        }
      end
    end

    def to_s
      @data.inspect
    end

    def delete(view)
      search_regex = '"' + @data[view].select{|d| d['status'] =~ /#{RupodModule::DELETE}/}.collect{|d| d[view]}
        .join('|')
        .gsub('"','\"')
        .gsub('(','\(')
        .gsub(')','\)')
        .gsub('[','\[')
        .gsub(']','\]') + '"'
      search_string = "#{GNUPOD_SEARCH_SCRIPT} --#{view}=#{search_regex} --delete"
      puts search_string
      puts `#{search_string}`
    end

  end

  class Albums < Gnupod
    attr_reader :albums
    def initialize
      @view = 'album'
    end
  end

  class Artists < Gnupod
    attr_reader :artists
    def initialize
      @view = 'artist'
    end
  end

end


module RupodModule
  COLS = 4
  KEEP=' '
  DELETE='X'
  MACRO=<<-EOF
   ______ _______ ______ _______ _____  
  |   == \\   !   |   == \\       |     \\ 
  |      <   !   |    __/   =   |  ==  |
  |___|__|_______|___|  |_______|_____/  v0.0.4

  EOF

  MENU_CHOICES=<<-EOF

  What would you like to do today?

          1)      Type numbers separated by a space to selectively delete
          2)      a to toggle all
          3)      c to commit changes
          4)      q to quit
          5)      t to toggle album/artist view 
                
  EOF
end

class Rupod

  def initialize
    @data = Gnupod::Gnupod.new
    @view = 'artist' if @view.nil?
    self.menu
    self.input_loop
  end

  def about
    # Filesystem    Type    Size  Used Avail Use% Mounted on
    # /dev/sde1     vfat    7.5G  3.4G  4.1G  46% /mnt/ipod
    return `df -h #{Gnupod::IPOD}`
  end
 
  def menu
    system('clear')
    puts RupodModule::MACRO
    puts self.about; puts
    puts "Showing #{@view} view"; puts
    if @data[@view].empty?
      puts "No data, mang.  Goobye"
      puts @data.inspect
      exit
    end
    max = @data[@view].max{|a,b| a[@view].length <=> b[@view].length}[@view].length + 5
    rows = (@data[@view]/RupodModule::COLS)
    rows.each_with_index do |group,i|
      group = group.collect{|g| "#{g['status']} #{g['index']}\t#{g[@view]}"}
      puts sprintf("%-#{max}s " * group.length, *group)
    end
    puts RupodModule::MENU_CHOICES
  end

  def toggle_delete(n)
    begin
      n = Integer(n)
      @data[@view][n]['status'] = @data[@view][n]['status'] ==
        RupodModule::DELETE ?  RupodModule::KEEP : RupodModule::DELETE
    rescue
      return
    end
  end

  def toggle_view
    if @view == 'artist'
      @view = 'album'
    else
      @view = 'artist'
    end
  end

  def input_loop
    while input = STDIN.gets.chop!
      case input
      when /T/i
        self.toggle_view
      when /Q/i
        puts "Happy listening!"
        system("mktunes.pl")
        exit
      when /C/i
        @data.delete(@view)
        system("mktunes.pl")
        @data = Gnupod::Gnupod.new
      when /A/i
        @data[@view].each_index{|i| self.toggle_delete(i)}
      when  /^(\d+\s?)?/
        input.split(/\s/).each do |i|
          self.toggle_delete(i)
        end
      end
      self.menu
    end
  end

end

#Gnupod::Gnupod.new

Rupod.new
