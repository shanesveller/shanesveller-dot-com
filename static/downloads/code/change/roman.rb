class RomanNumeral
  attr_accessor :latin, :roman
  CONVERSIONS = {
    1000 => "M",
    500 => "D",
    100 => "C",
    50 => "L",
    10 => "X",
    5 => "V",
    1 => "I"
  }
  SIMPLIFICATIONS = {
    "DCCCC" => "CM",
    "CCCC" => "CD",
    "LXXXX" => "XC",
    "XXXX" => "XL",
    "VIIII" => "IX",
    "IIII" => "IV"
  }

  def initialize(integer)
    @latin = integer
    @roman = ""
    while (integer >= 1)
      for num in CONVERSIONS.keys
        if integer >= num
          integer -= num
          @roman += CONVERSIONS[num]
          break
        end
      end
    end
    simplify
  end

  def simplify
    SIMPLIFICATIONS.each {|normal, simple| @roman.gsub!(normal, simple) }
  end

  def to_s
    @roman
  end
end
