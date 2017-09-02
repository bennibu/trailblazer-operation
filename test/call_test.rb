require "test_helper"

class CallTest < Minitest::Spec
  describe "::call" do
    class Create < Trailblazer::Operation
      step ->(*) { true }
      def inspect
        "#{@skills.inspect}"
      end
    end

    it { Create.().must_be_instance_of Trailblazer::Operation::Railway::Result }

    # it { Create.({}).inspect.must_equal %{<Result:true <Skill {} {\"params\"=>{}} {\"pipetree\"=>[>operation.new]}> >} }
    # it { Create.(name: "Jacob").inspect.must_equal %{<Result:true <Skill {} {\"params\"=>{:name=>\"Jacob\"}} {\"pipetree\"=>[>operation.new]}> >} }
    # it { Create.({ name: "Jacob" }, { policy: Object }).inspect.must_equal %{<Result:true <Skill {} {:policy=>Object, \"params\"=>{:name=>\"Jacob\"}} {\"pipetree\"=>[>operation.new]}> >} }

    #---
    # success?
    class Update < Trailblazer::Operation
      step ->(options, **) { options["params"] }
    end

    # operation success
    it do
      result = Update.(true)

      result.success?.must_equal true

      result.event.must_be_instance_of Trailblazer::Operation::Railway::End::Success
      result.event.must_equal Update.outputs.keys[0]
    end

    # operation failure
    it do
      result = Update.(false)

      result.success?.must_equal false
      result.failure?.must_equal true

      result.event.must_be_instance_of Trailblazer::Operation::Railway::End::Failure
      result.event.must_equal Update.outputs.keys[1]
    end

  end
end

