#!/usr/bin/env ruby
#
# rupod : express yourself
# (c) 2010 Noah K. Tilton
#
# Released under the terms of the MIT license:
#       http://www.opensource.org/licenses/mit-license.php

require 'pp'

class String
  def in_path? 
    return ! /no #{self} in/.match(`which #{self} 2>&1`)
  end
end

module Gnupod

  GNUPOD_SEARCH_SCRIPT='gnupod_search.pl'

  class Artists

    include Enumerable

    attr_reader :artists

    def initialize
      self.setup
      @artists = self.update
    end

    def / len
      a = []
      each_with_index do |x,i|
        a << [] if i % len == 0
        a.last << x
      end
      a
    end

    def [](n)
      @artists[n]
    end

    def each
      @artists.each { |i| yield i }
    end

    def each_index
      @artists.each_index { |i| yield i }
    end

    def setup
      if ! GNUPOD_SEARCH_SCRIPT.in_path?
        puts "#{GNUPOD_SEARCH_SCRIPT} not found in path, exiting . . ." 
        exit -1
      end
    end

    def update
      artists=`#{GNUPOD_SEARCH_SCRIPT}|awk -F'|' '{print $2}' |sort|uniq`.lstrip.split(/\n/).collect{|item| item.strip}.reject{|item| item =~ /ARTIST/ }
      artists.length.times do |i|
        artists[i] = {
            'artist' => artists[i],
            'status' => RupodModule::KEEP,
            'index' => i
          }
      end
      artists
    end

    def delete
      search_regex = '"' + @artists.select{|artist| artist['status'] =~ /#{RupodModule::DELETE}/}.collect{|artist| artist['artist']}.join('|') + '"'
      search_string = "#{GNUPOD_SEARCH_SCRIPT} --artist=#{search_regex} --delete"
      puts `#{search_string}`
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
  |___|__|_______|___|  |_______|_____/  v1.0  pre-alpha

  EOF

  MENU_CHOICES=<<-EOF

  What would you like to do today?

          1)      Select numbers (optionally) separated by a space to selectively delete.
          2)      Type "ALL" to toggle all.
          3)      When you're ready, type "GO".
          4)      Type "Q" to quit.
                
  EOF
end

class Rupod
  def initialize
    @artists = Gnupod::Artists.new
    # TODO @albums = Gnupod::Albums.new
    self.menu
    self.input_loop
  end

  def menu
    system('clear')
    puts RupodModule::MACRO
    max = @artists.max{|a,b| a['artist'].length <=> b['artist'].length}['artist'].length + 5
    rows = (@artists/RupodModule::COLS)
    rows.each_with_index do |group,i|
      group = group.collect{|g| "#{g['status']} #{g['index']}\t#{g['artist']}"}
      puts sprintf("%-#{max}s " * group.length, *group)
    end
    puts RupodModule::MENU_CHOICES
  end

  def toggle_delete(n)
    begin
      n = Integer(n)
      @artists[n]['status'] = @artists[n]['status'] ==
        RupodModule::DELETE ?  RupodModule::KEEP : RupodModule::DELETE
    rescue
      return
    end
  end

  def input_loop
    while input = STDIN.gets.chop!
      case input
      when /Q/i
        puts "Happy listening!"
        exit
      when /GO/i
        @artists.delete
        @artists = Gnupod::Artists.new
      when /ALL/i
        @artists.each_index{|i| self.toggle_delete(i)}
      when  /^(\d+\s?)?/
        input.split(/\s/).each do |i|
          self.toggle_delete(i)
        end
      end
      self.menu
    end
  end

end

Rupod.new
