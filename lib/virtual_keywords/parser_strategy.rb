module VirtualKeywords
  class ParserStrategy
    # Factory method
    # Create the appropriate strategy object for the current Ruby version.
    def self.new
      if RUBY_VERSION.start_with? '1.8'
        ParseTreeStrategy.new(ParseTree, SexpProcessor.new)
      else
        #RubyParserStrategy.new(RubyParser.new)
        SourcifyStrategy.new
      end
    end
  end

  # One problem that needs to be solved is that of converting source code form
  # files into sexps.

  # In Ruby 1.8, we use ParseTree and then SexpProcessor.
  # In Ruby 1.9, we use RubyParser.
  # Note that neither set of libraries seems to work in the other version.
  # Use the strategy pattern, and initialize whichever class is appropriate.

  # Parser strategy that uses ParseTree
  class ParseTreeStrategy
    # Initialize a ParseTreeStrategy
    #
    # Arguments:
    #   parse_tree: (Class) an instance of the ParseTree singleton, that
    #       translates code into ParseTree output.
    #   sexp_processor: (SexpProcessor) an object that translates ParseTree
    #       output into rewriteable sexps.
    def initialize(parse_tree, sexp_processor)
      @parse_tree = parse_tree
      @sexp_processor = sexp_processor
    end

    # Translate an instance method of a class.
    # 
    # Arguments:
    #   klass: (Class) the class.
    #   method_name: (String) the name of the method to translate.
    #
    # Returns:
    #   (Sexp) the method, turned into a sexp.
    def translate_instance_method(klass, method_name)
      @sexp_processor.process(@parse_tree.translate(klass, method_name))
    end
  end

  # Parser strategy that uses ruby_parser
  class RubyParserStrategy
    def initialize ruby_parser
      @ruby_parser = ruby_parser
    end

    # Translate an instance method of a class.
    # 
    # Arguments:
    #   klass: (Class) the class.
    #   method_name: (String) the name of the method to translate.
    #
    # Returns:
    #   (Sexp) the method, turned into a sexp.
    def translate_instance_method(klass, method_name)
      @ruby_parser.parse(klass.instance_method(method_name).source)
    end
  end

  # Parser strategy that uses sourcify
  class SourcifyStrategy
    def initialize
      #nothing?
    end

    # Translate an instance method of a class.
    # 
    # Arguments:
    #   klass: (Class) the class.
    #   method_name: (String) the name of the method to translate.
    #
    # Returns:
    #   (Sexp) the method, turned into a sexp.
    def translate_instance_method(klass, method_name)
      meth = klass.new.method(method_name)
      meth.to_sexp
    end
  end
end
