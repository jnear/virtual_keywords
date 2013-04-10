module VirtualKeywords
  # SexpProcessor subclass that rewrites "if" expressions.
  # Calls VirtualKeywords::REWRITTEN_KEYWORDS.call_if and lets it pick a
  # virtual implementation.
  class IfRewriter < SexpProcessor
    # Initialize an IfRewriter (self.strict is false)
    def initialize
      super
      self.strict = false
    end

    # Rewrite an :if sexp. SexpProcessor#process is a template method that will
    # call this method every time it encounters an :if.
    #
    # Arguments:
    #   expression: (Sexp) the :if sexp to be rewritten.
    #
    # Returns:
    #   (Sexp) A rewritten sexp that calls
    #   VirtualKeywords::REWRITTEN_KEYWORDS.call_if with the condition,
    #   then clause, and else clause as arguments, all wrapped in lambdas.
    #   It must also pass self to call_if, so REWRITTEN_KEYWORDS can decide
    #   which of the lambdas registered with it should be called.
    def rewrite_if(expression)
      # The sexp for the condition passed to if is inside expression[1]
      # We can further process this sexp if it has and/or in it.
      condition = expression[1]
      then_do = expression[2]
      else_do = expression[3]

      # This ugly sexp turns into the following Ruby code:
      # VirtualKeywords::REWRITTEN_KEYWORDS.call_if(
      #     self, lambda { condition }, lambda { then_do }, lambda { else_do })
      # s(:call,
      #   s(:colon2,
      #     s(:const, :VirtualKeywords),
      #     :REWRITTEN_KEYWORDS
      #   ), :call_if,
      #   s(:array,
      #     s(:self),
      #     s(:iter, s(:fcall, :lambda), nil, condition),
      #     s(:iter, s(:fcall, :lambda), nil, then_do),
      #     s(:iter, s(:fcall, :lambda), nil, else_do)
      #   )
      # )

      s(:iter, s(:call, nil, :proc, s(:arglist)), nil, 
        s(:call,
          s(:colon2, s(:const, :VirtualKeywords), :REWRITTEN_KEYWORDS),
          :call_if, s(:arglist, s(:self), 
                      s(:iter, s(:call, nil, :lambda,
                                 s(:arglist)), nil, condition), 
                      s(:iter, s(:call, nil, :lambda,
                                 s(:arglist)), nil, then_do), 
                      s(:iter, s(:call, nil, :lambda,
                                 s(:arglist)), nil, else_do)))) 
    end
  end

  # Helper method. Call a 2-argument function used to replace an operator
  # (like "and" or "or")
  #
  # Arguments:
  #   method_name: (Symbol) the name of the REWRITTEN_KEYWORDS method that
  #       should be called in the sexp.
  #   first: (Sexp) the first argument to the method, which should be
  #       wrapped in a lambda then passed to REWRITTEN_KEYWORDS. 
  #   second: (Sexp) the second argument to the method, which should be
  #       wrapped in a lambda then passed to REWRITTEN_KEYWORDS. 
  def self.call_operator_replacement(function_name, first, second)
    # s(:call,
    #   s(:colon2,
    #     s(:const, :VirtualKeywords),
    #     :REWRITTEN_KEYWORDS
    #   ), function_name,
    #   s(:array,
    #     s(:self),
    #     s(:iter, s(:fcall, :lambda), nil, first),
    #     s(:iter, s(:fcall, :lambda), nil, second)
    #   )
    # )

    s(:iter, s(:call, nil, :proc, s(:arglist)), nil, 
      s(:call, s(:colon2, s(:const, :VirtualKeywords), :REWRITTEN_KEYWORDS), 
        function_name, 
        s(:arglist, s(:self), 
          s(:iter, s(:call, nil, :lambda, s(:arglist)), nil, first), 
          s(:iter, s(:call, nil, :lambda, s(:arglist)), nil, second))))
  end

  # SexpProcessor subclass that rewrites "and" expressions.
  class AndRewriter < SexpProcessor
    def initialize
      super
      self.strict = false
    end

    # Rewrite "and" expressions (automatically called by SexpProcessor#process)
    #
    # Arguments:
    #   expression: (Sexp) the :and sexp to rewrite.
    #
    # Returns:
    #   (Sexp): a sexp that instead calls REWRITTEN_KEYWORDS.call_and
    def rewrite_and(expression)
      first = expression[1]
      second = expression[2]

      VirtualKeywords.call_operator_replacement(:call_and, first, second)
    end
  end

  # SexpProcessor subclass that rewrites "or" expressions.
  class OrRewriter < SexpProcessor
    def initialize
      super
      self.strict = false
    end
  
    # Rewrite "or" expressions (automatically called by SexpProcessor#process)
    #
    # Arguments:
    #   expression: (Sexp) the :or sexp to rewrite.
    #
    # Returns:
    #   (Sexp): a sexp that instead calls REWRITTEN_KEYWORDS.call_or
    def rewrite_or(expression)
      first = expression[1]
      second = expression[2]

      VirtualKeywords.call_operator_replacement(:call_or, first, second)
    end
  end

  # SexpProcessor subclass that rewrites "not" expressions.
  class NotRewriter < SexpProcessor
    def initialize
      super
      self.strict = false
    end

    # Rewrite "not" expressions (automatically called by SexpProcessor#process)
    #
    # Arguments:
    #   expression: (Sexp) the :not sexp to rewrite.
    #
    # Returns:
    #   (Sexp): a sexp that instead calls REWRITTEN_KEYWORDS.call_not
    def rewrite_not(expression)
      value = expression[1]

      # s(:call,
      #   s(:colon2,
      #     s(:const, :VirtualKeywords),
      #     :REWRITTEN_KEYWORDS
      #   ), :call_not,
      #   s(:array,
      #     s(:self),
      #     s(:iter, s(:fcall, :lambda), nil, value)
      #   )
      # )

      s(:iter, s(:call, nil, :proc, s(:arglist)), nil, 
        s(:call, s(:colon2, s(:const, :VirtualKeywords), :REWRITTEN_KEYWORDS), 
          :call_not, 
          s(:arglist, s(:self), 
            s(:iter, s(:call, nil, :lambda, s(:arglist)), nil, value))))
    end
  end

  # Raised if a rewriter encounters an unexpected sexp, indicating a bug.
  class UnexpectedSexp < StandardError
  end

  # SexpProcessor subclass that rewrites "while" expressions.
  class WhileRewriter < SexpProcessor
    def initialize
      super
      self.strict = false
    end

    # Rewrite "while" expressions (automatically called by SexpProcessor#process)
    #
    # Arguments:
    #   expression: (Sexp) the :while sexp to rewrite.
    #
    # Returns:
    #   (Sexp): a sexp that instead calls REWRITTEN_KEYWORDS.call_while
    def rewrite_while(expression)
      condition = expression[1]
      body = expression[2]
      
      # This was a true in the example I checked (in sexps_while.txt)
      # but I'm not sure what it's for.
      third = expression[3]
      if third != true # Should be true, not just a truthy object
        raise UnexpectedSexp, 'Expected true as the 3rd element in a while, ' +
            "but got #{third}, this is probably a bug."
      end

      # s(:call,
      #   s(:colon2,
      #     s(:const, :VirtualKeywords),
      #     :REWRITTEN_KEYWORDS
      #   ), :call_while,
      #   s(:array,
      #     s(:self),
      #     s(:iter, s(:fcall, :lambda), nil, condition),
      #     s(:iter, s(:fcall, :lambda), nil, body)
      #   )
      # )

      s(:iter, s(:call, nil, :proc, s(:arglist)), nil, 
        s(:call, s(:colon2, s(:const, :VirtualKeywords), :REWRITTEN_KEYWORDS), 
          :call_while, s(:arglist, s(:self), 
                         s(:iter, s(:call, nil, :lambda, s(:arglist)), nil, condition), 
                         s(:iter, s(:call, nil, :lambda, s(:arglist)), nil, body))))
    end
  end

  # SexpProcessor subclass that rewrites "until" expressions.
  class UntilRewriter < SexpProcessor
    def initialize
      super
      self.strict = false
    end

    # Rewrite "until" expressions (automatically called by SexpProcessor#process)
    #
    # Arguments:
    #   expression: (Sexp) the :until sexp to rewrite.
    #
    # Returns:
    #   (Sexp): a sexp that instead calls REWRITTEN_KEYWORDS.call_until
    def rewrite_until(expression)
      condition = expression[1]
      body = expression[2]
      
      # This was a true in the example I checked (in sexps_while.txt)
      # but I'm not sure what it's for.
      third = expression[3]
      if third != true # Should be true, not just a truthy object
        raise UnexpectedSexp, 'Expected true as the 3rd element in a while, ' +
            "but got #{third}, this is probably a bug."
      end

      # s(:call,
      #   s(:colon2,
      #     s(:const, :VirtualKeywords),
      #     :REWRITTEN_KEYWORDS
      #   ), :call_until,
      #   s(:array,
      #     s(:self),
      #     s(:iter, s(:fcall, :lambda), nil, condition),
      #     s(:iter, s(:fcall, :lambda), nil, body)
      #   )
      #   )
      s(:iter, s(:call, nil, :proc, s(:arglist)), nil, 
        s(:call, s(:colon2, s(:const, :VirtualKeywords), :REWRITTEN_KEYWORDS), 
          :call_until, s(:arglist, s(:self), 
                         s(:iter, s(:call, nil, :lambda, s(:arglist)), nil, condition), 
                         s(:iter, s(:call, nil, :lambda, s(:arglist)), nil, body))))
    end
  end
end
