require "grok-pure"

class Grok::Match
  attr_accessor :subject
  attr_accessor :grok
  attr_accessor :match

  public
  def initialize
    @captures = nil
  end

  public
  def each_capture
    @match.names.zip(@match.captures).each do |id, value|
      if !@grok.named_captures_only
        name = @grok.capture_name(id) || "_:#{id}"
        yield name, value
      else
        yield id, value
      end
    end

  end # def each_capture

  public
  def captures
    if @captures.nil?
      @captures = Hash.new { |h,k| h[k] = [] }
      each_capture do |key, val|
        @captures[key] << val
      end
    end
    return @captures
  end # def captures

  public
  def [](name)
    return captures[name]
  end # def []
end # Grok::Match
