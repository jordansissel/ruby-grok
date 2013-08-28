require "rubygems"
require "logger"
require "grok/pure/discovery"
require "cabin"

# TODO(sissel): Check if 'grok' c-ext has been loaded and abort?
class Grok
  class PatternError < StandardError; end

  # The pattern input
  attr_accessor :pattern
  
  # The fully-expanded pattern (in regex form)
  attr_accessor :expanded_pattern

  # The logger
  attr_accessor :logger

  # The dictionary of pattern names to pattern expressions
  attr_accessor :patterns
  
  PATTERN_RE = \
    /%\{    # match '%{' not prefixed with '\'
       (?<name>     # match the pattern name
         (?<pattern>[A-z0-9]+)
         (?::(?<subname>[@\[\]A-z0-9_:.-]+))?
       )
       (?:=(?<definition>
         (?:
           (?:[^{}\\]+|\\.+)+
           |
           (?<curly>\{(?:(?>[^{}]+|(?>\\[{}])+)|(\g<curly>))*\})+
         )+
       ))?
       [^}]*
     \}/x

  GROK_OK = 0
  GROK_ERROR_FILE_NOT_ACCESSIBLE = 1
  GROK_ERROR_PATTERN_NOT_FOUND = 2
  GROK_ERROR_UNEXPECTED_READ_SIZE = 3
  GROK_ERROR_COMPILE_FAILED = 4
  GROK_ERROR_UNINITIALIZED = 5
  GROK_ERROR_PCRE_ERROR = 6
  GROK_ERROR_NOMATCH = 7

  public
  def initialize
    @patterns = {}
    @logger = Cabin::Channel.new
    @logger.subscribe(Logger.new(STDOUT))
    @logger.level = :warn

    # TODO(sissel): Throw exception if we aren't using Ruby 1.9.2 or newer.
  end # def initialize

  public
  def add_pattern(name, pattern)
    @logger.info("Adding pattern", name => pattern)
    @patterns[name] = pattern
    return nil
  end # def add_pattern

  public
  def add_patterns_from_file(path)
    file = File.new(path, "r")
    file.each do |line|
      # Skip comments
      next if line =~ /^\s*#/ 
      # File format is: NAME ' '+ PATTERN '\n'
      name, pattern = line.gsub(/^\s*/, "").split(/\s+/, 2)
      #p name => pattern
      # If the line is malformed, skip it.
      next if pattern.nil?
      # Trim newline and add the pattern.
      add_pattern(name, pattern.chomp)
    end
    return nil
  end # def add_patterns_from_file

  public
  def compile(pattern)
    @capture_map = {}

    iterations_left = 10000
    @pattern = pattern
    @expanded_pattern = pattern.clone
    index = 0

    # Replace any instances of '%{FOO}' with that pattern.
    loop do
      if iterations_left == 0
        raise PatternError, "Deep recursion pattern compilation of #{pattern.inspect} - expanded: #{@expanded_pattern.inspect}"
      end
      iterations_left -= 1
      m = PATTERN_RE.match(@expanded_pattern)
      break if !m

      if m["definition"]
        add_pattern(m["pattern"], m["definition"])
      end

      if @patterns.include?(m["pattern"])
        # create a named capture index that we can push later as the named
        # pattern. We do this because ruby regexp can't capture something
        # by the same name twice.
        regex = @patterns[m["pattern"]]
        #puts "patterns[#{m["pattern"]}] => #{regex}"

        capture = "a#{index}" # named captures have to start with letters?
        #capture = "%04d" % "#{index}" # named captures have to start with letters?
        replacement_pattern = "(?<#{capture}>#{regex})"
        @capture_map[capture] = m["name"]

        #puts "Before: #{@expanded_pattern}"
        #puts "m[0]: #{m[0]}"
        #puts "replacement_pattern => #{replacement_pattern}"
        #puts "Proposed: #{@expanded_pattern.sub(m[0], replacement_pattern)}"

        # Ruby's String#sub() has a bug (or misfeature) that causes it to do bad
        # things to backslashes in string replacements, so let's work around it
        # See this gist for more details: https://gist.github.com/1491437
        # This hack should resolve LOGSTASH-226.
        @expanded_pattern.sub!(m[0]) { |s| replacement_pattern }

        #puts "After: #{@expanded_pattern}"
        #puts "m[0]: #{m[0]}"
        #puts "replacement_pattern => #{replacement_pattern}"
        index += 1
      else
        raise PatternError, "pattern #{m[0]} not defined"
      end
    end

    #@logger.debug("Finished expanding", :string => @expanded_pattern)
    #puts "Expanded: #{@expanded_pattern}"
    @regexp = Regexp.new(@expanded_pattern)
    @logger.debug("Grok compiled OK", :pattern => pattern,
                  :expanded_pattern => @expanded_pattern)
  end # def compile

  public
  def match(text)
    match = @regexp.match(text)

    if match
      grokmatch = Grok::Match.new
      grokmatch.subject = text
      grokmatch.start, grokmatch.end = match.offset(0)
      grokmatch.grok = self
      grokmatch.match = match
      @logger.debug("Regexp match object", :names => match.names, :captures => match.captures)
      return grokmatch
    else
      return false
    end
  end # def match

  public
  def discover(input)
    init_discover if @discover == nil

    return @discover.discover(input)
  end # def discover

  private
  def init_discover
    require "grok/pure/discovery"
    @discover = Grok::Discovery.new(self)
    @discover.logger = @logger
  end # def init_discover

  public
  def capture_name(id)
    return @capture_map[id]
  end # def capture_name
end # Grok

require "grok/pure/match"
require "grok/pure/pile"
