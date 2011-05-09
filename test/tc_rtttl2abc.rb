require "test/unit"

require_relative "../lib/rtttl2abc"

class TestRtttl2ABC < Test::Unit::TestCase
  def setup
    extend Rtttl2ABC
  end

  RTTTL =<<STR
:lead
 8E5 8E5 8 8E5 8 8C5 4E5  4G5 4 4G4 4           4C5 8 8G4 4 4E4   8 4A4 4B4 8A#4 4A4
 6G4 6E5 6G5 4A5 8F5 8G5  8 4E5 8C5 8D5 4B4 8   4C5 8 8G4 4 4E4   8 4A4 4B4 8A#4 4A4
:lead2
 8E5 8E5 8 8E5 8 8C5 4E5  4G5 4 4G4 4           4C5 8 8G4 4 4E4   8 4A4 4B4 8A#4 4A4
 6G4 6E5 6G5 4A5 8F5 8G5  8 4E5 8C5 8D5 4B4 8   4C5 8 8G4 4 4E4   8 4A4 4B4 8A#4 4A4
STR

  def test_read_rtttl
    score = read_rtttl(RTTTL)
    assert_equal("8E5 8E5 8 8E5 8 8C5 4E5", score[:lead][0][0,23])
    assert_equal("4C5 8 8G4 4 4E4   8 4A4 4B4 8A#4 4A4", score[:lead2][1][47, 36])
  end

  def test_to_abc
    samples = {"8E5" => "e1", "4E5" => "e2", "8C4" => "C1", "8A6" => "a'1", "8B3" => "B,1",
               "8" => "z1", "4" => "z2", "8A#4" => "^A1"}
    samples.each do |rtttl, abc|
      assert_equal(abc, to_abc(rtttl, 8))
    end
  end

  def test_to_abc_with_length
    samples = {"8E5" => "e1/2", "4E5" => "e1", "8C4" => "C1/2", "8A6" => "a'1/2", "8B3" => "B,1/2",
               "8" => "z1/2", "4" => "z1", "8A#4" => "^A1/2"}
    samples.each do |rtttl, abc|
      assert_equal(abc, to_abc(rtttl, 4))
    end
  end

  def test_to_abc_error
    error = Rtttl2ABC::ConversionError
    assert_raise(error) { to_abc("8A9") }
    assert_raise(error) { to_abc("B1") }
  end

  def test_convert
    rtttl =<<RTTTL
:lead
 8E5 8E5 8 8E5 8 8C5 4E5    4G5 4 4G4 4   4C5 8 8G4 4 4E4   8 4A4 4B4 8A#4 4B4 12A2
:lead2
 8F#4 8F#4 8 8F#4 8 8F#4 4F#4   4G4 4 4G4 4   4E4 8 8E4 4 4C4    8 4C4 4D4 8C#4 4C4
RTTTL
    abc = {:lead => ["e1 e1 z1 e1 z1 c1 e2 | g2 z2 G2 z2 | c2 z1 G1 z2 E2 | z1 A2 B2 ^A1 B2 =A,,2/3"],
           :lead2 => ["^F1 ^F1 z1 ^F1 z1 ^F1 ^F2 | G2 z2 G2 z2 | E2 z1 E1 z2 C2 | z1 C2 D2 ^C1 =C2"]}
    assert_equal(abc, convert(rtttl))
  end

  def test_add_natural_sign
    rtttls  = [ {:lead => ["4B4 8A#4 4A4 4A2"]},
                {:lead => ["4B4 8A#4 4A4", "8C3 4A5"]},
                {:lead => ["4B#4 4B3", "5C#5 4B3 4C5"]},
                {:lead => ["4B#4 4B3"], :lead2 => ["5C#5 4B3 4C5"]},
                {:lead2 => ["8F#4 8F#4 8 8F#4 8 8F#4 4F#4   4G4 4 4G4 4   4E4 8 8E4 4 4C4    8 4C4 4D4 8C#4 4C4"]},
                {:lead => ["4 8G5 8F#5 8F5 4D#5 8E5  8 8G#4 12A4 8C5 8 8A4 8C5 8D5 8"]} ]
    results = [ {:lead => ["4B4 8A#4 4A=4 4A=2"]},
                {:lead => ["4B4 8A#4 4A=4", "8C3 4A=5"]},
                {:lead => ["4B#4 4B=3", "5C#5 4B=3 4C=5"]},
                {:lead => ["4B#4 4B=3"], :lead2 => ["5C#5 4B3 4C=5"]},
                {:lead2 => ["8F#4 8F#4 8 8F#4 8 8F#4 4F#4   4G4 4 4G4 4   4E4 8 8E4 4 4C4    8 4C4 4D4 8C#4 4C=4"]},
                {:lead => ["4 8G5 8F#5 8F=5 4D#5 8E5  8 8G#4 12A4 8C5 8 8A4 8C5 8D=5 8"]} ]
    rtttls.each_with_index do |rtttl, i|
      assert_equal(results[i], add_natural_sign(rtttl))
    end
  end

  def test_add_pitch
    rtttls  = [ {:lead => ["4B 8A# 4A 4A"]},
                {:lead => ["4B 8A# 4A", "+ 8C 4A"]},
                {:lead => ["4B 8A# 4A", "++ 8C 4A"]},
                {:lead => ["4B 8A# 4A", "+ 8C 4A - 4A 8 4C"]},
                {:lead => ["4B 8A# 4A", "+ 8C 4A - 4A 8 12C  4B 5C#"]},
                {:lead => ["+ 2A# 12 12A# 12A# 12A# 12G# 12F#   6G# 12F# 2F 4F", "+ 8D# 16D# 16F 2F# 8F 8D#  8C# 16C# 16D# 2F 8D# 8C#"]} ]
    results = [ {:lead => ["4B5 8A#5 4A5 4A5"]},
                {:lead => ["4B5 8A#5 4A5", "8C6 4A6"]},
                {:lead => ["4B5 8A#5 4A5", "8C7 4A7"]},
                {:lead => ["4B5 8A#5 4A5", "8C6 4A6 4A5 8 4C5"]},
                {:lead => ["4B5 8A#5 4A5", "8C6 4A6 4A5 8 12C5  4B5 5C#5"]},
                {:lead => ["2A#6 12 12A#6 12A#6 12A#6 12G#6 12F#6   6G#6 12F#6 2F6 4F6", "8D#6 16D#6 16F6 2F#6 8F6 8D#6  8C#6 16C#6 16D#6 2F6 8D#6 8C#6"]} ]
    rtttls.each_with_index do |rtttl, i|
      assert_equal(results[i], add_pitch(rtttl, 5))
    end
  end

  def test_convert_with_format
    result = convert_with_format(RTTTL) {{
      T:"Paddy O'Rafferty",
      L:"1/8",
      Q:'"allegro" 1/4=120'
    }}
    puts result
  end
end
