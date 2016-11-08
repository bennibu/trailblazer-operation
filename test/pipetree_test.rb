require "test_helper"

class PipetreeTest < Minitest::Spec
  module Validate
    extend Trailblazer::Operation::Stepable

    def self.import!(operation, pipe)
      pipe.(:>, ->{ snippet }, name: "validate", before: "operation.new")
    end
  end

  #---
  # ::|
  # without options
  class Create < Trailblazer::Operation
    self.| Validate[]
  end

  it { Create["pipetree"].inspect.must_equal %{[>validate,>>operation.new]} }

  # without any options or []
  class New < Trailblazer::Operation
    self.| Validate
  end

  it { New["pipetree"].inspect.must_equal %{[>validate,>>operation.new]} }


  # with options
  class Update < Trailblazer::Operation
    self.| Validate, after: "operation.new"
  end

  it { Update["pipetree"].inspect.must_equal %{[>>operation.new,>validate]} }

  # with :symbol
  class Delete < Trailblazer::Operation
    self.| :call!

    def call!(options)
      self["x"] = options["params"]
    end
  end

  it { Delete.("yo")["x"].must_equal "yo" }

  #---
  # arguments
  class Forward < Trailblazer::Operation
    self.| ->(input, options) { puts "@@@@@ #{input.inspect}"; puts "@@@@@ #{options.inspect}" }
  end

  it { skip; Forward.({ id: 1 }) }
end


# args: operation, skills
