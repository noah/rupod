require 'pp'
class String
  def in_path? 
    return ! /no #{self} in/.match(`which #{self} 2>&1`)
  end
end

module Gnupod

  SEARCH_SCRIPT='gnupod_search.pl'
  LINE_DELIMITER='\n'
  FIELD_DELIMITER='|'

  class Ipod
    def setup
      if ! Gnupod::SEARCH_SCRIPT.in_path?
        puts "#{Gnupod::SEARCH_SCRIPT} not found in path, exiting . . ." 
        exit -1
      end
      self.update
    end

    def / len
      a = []
      each_with_index do |x,i|
        a << [] if i % len == 0
        a.last << x
      end
      a
    end

    def update
      for row in `#{Gnupod::SEARCH_SCRIPT}`.lstrip.split(/#{Gnupod::LINE_DELIMITER}/).inject([]){|arr,line| arr<<line.split('|')[1..2]}.sort.uniq do
      end
      exit
      artists.length.times do |i|
        artists[i] = {
            'name' => artists[i],
            'status' => RupodModule::KEEP,
            'index' => i
          }
      end
      artists
    end
  end

  class Albums < Ipod
  end

  class Artists < Ipod

    include Enumerable

    attr_reader :artists

    def initialize
      self.setup
    end

    # def [](n)
    #   @artists[n]
    # end

    # def each
    #   @artists.each { |i| yield i }
    # end

    # def each_index
    #   @artists.each_index { |i| yield i }
    # end


    # def delete
    #   search_regex = '"' + @artists.select{|artist| artist['status'] =~ /#{RupodModule::DELETE}/}.collect{|artist| artist['artist']}.join('|') + '"'
    #   search_string = "#{GNUPOD_SEARCH_SCRIPT} --artist=#{search_regex} --delete"
    #   puts `#{search_string}`
    # end
  end

end



