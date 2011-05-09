require "mathn"

module Rtttl2ABC
  class ConversionError < StandardError; end

  def convert(rtttl_string, base_length=8, base_pitch=5)
    @base_length = base_length
    rtttl = read_rtttl(rtttl_string)
    rtttl = add_pitch(rtttl, base_pitch)
    rtttl = add_natural_sign(rtttl)
    _convert(rtttl)
  end

  def convert_with_format(rtttl, base_length=8, base_pitch=5)
    res = []
    if block_given?
       res += yield.to_a.map { |i| i.join ':' }
    end
    data = convert(rtttl, base_length, base_pitch)
    lead_labels = (1..data.keys.length).to_a
    data.values.transpose.each do |lines|
      lines.each do |line|
        res << "V:#{lead_labels.rotate!.last}"
        res << line
      end
    end
    res
  end

  def read_rtttl(score)
    q = Hash.new { |h,k| h[k]=[] }
    flag = :lead
    score.lines do |line|
      next if line =~ /^\s*$/
      case line
      when /^:(\w+)/ then flag = $1
      else
        q[flag.to_sym] << line.chomp.strip
      end
    end
    q
  end

  def _convert(rtttl)
    q = {}
    rtttl.each do |part, score|
      q[part] = 
        score.map do |line|
          atomize(line).map { |note| to_abc note }.join(" ")
        end
    end
    q
  end

  def to_abc(rtttl, base_length=@base_length)
    case rtttl
    when separater?
      rtttl
    when rest?
      "z" + length($&.to_i, base_length)
    when note?
      sharps($3) + pitch($2, $4) + length($1.to_i, base_length)
    else
      raise ConversionError, "wrong format rtttl given"
    end
  end

  def add_natural_sign(score)
    score.each do |part, note|
      sharps = {}
      note.map! do |line|
        sharps_in_line = line.scan(/[A-Ga-g][',]{0,2}(?=#)/).uniq
        unless sharps_in_line.empty?
          sharps_in_line.each { |sharp|  sharps[sharp] = true }
          sharps.each do |sharp, _|
            pos = line.index(/#{sharp}#/) || -sharp.size
            pre_sharp, post_sharp = split_at(line, pos+sharp.size)
            line = pre_sharp + _add_natural(post_sharp, [sharp])
          end
          line
        else
          sharps.empty? ? line : _add_natural(line, sharps.keys)
        end
      end
    end
    score
  end

  def add_pitch(score, pitch)
    default_pitch = pitch
    re = ['\d\d*[A-Ga-g][,\'#=]*\d*', '\++\s?', '\-+\s?', '\d\d*', '\s+']
    score.each do |part, note|
      note.map! do |line|
        new_line = ""
        line.scan(/#{re.join('|')}/).each do |atom|
          new_line <<
            case atom
            when /\d+[A-Ga-g][,\'#=]*$/ then "#{atom}#{pitch}"
            when /#{re[1]}/ then pitch += $&.size-1; ""
            when /#{re[2]}/ then pitch -= $&.size-1; ""
            else atom
            end
        end
        pitch = default_pitch
        new_line
      end
    end
    score
  end

  private
  def split_at(str, pos)
    return str[0, pos+1], str[pos+1, str.length]
  end

  def atomize(line)
    insert_separator(line).split(/\s+/)
  end

  def insert_separator(note)
    note.gsub(/\s{2,}/, ' | ')
  end

  def separater?
    '|'
  end

  def rest?
    /^\d\d*p*$/
  end
  
  def note?
    /^(\d\d*)([A-Ga-g])([#=]*)(\d)$/
  end

  def length(n, base)
    "#{base/n}"
  end

  def sharps(mark)
    {'#' => '^', '=' => '='}[mark] || ''
  end

  def pitch(alphabet, octave)
    case octave.to_i
    when 2 then alphabet + ",,"
    when 3 then alphabet + ","
    when 4 then alphabet
    when 5 then alphabet.downcase
    when 6 then alphabet.downcase + "'"
    when 7 then alphabet.downcase + "''"
    else raise ConversionError, "wrong pitch number given"
    end
  end
  
  def _add_natural(str, sharps)
    str.gsub(/#{sharps.join('|')}(?=\d+)/, '\0=')
  end
end

