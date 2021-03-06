require 'test_helper'

class TestDependencyOne
  attr_reader :arg
  def initialize(arg = nil)
    @arg = arg
  end
end
class TestDependencyTwo
  attr_reader :arg
  def initialize(arg = nil)
    @arg = arg
  end
end

class TestContainer < Proxy::DependencyInjection::Container; end

module TestInjectors
  include Proxy::DependencyInjection::Accessors

  def container_instance
    TestContainer.instance
  end
end

class TestDependencies
  extend Proxy::DependencyInjection::Wiring

  def self.container_instance
    TestContainer.instance
  end

  dependency :test_dependency_one, TestDependencyOne
  dependency :test_dependency_two, -> { TestDependencyOne.new("a_parameter") }
  singleton_dependency :singleton_dependency, TestDependencyTwo
  singleton_dependency :singleton_dependency_two, -> { TestDependencyTwo.new("a_parameter") }
end

class TestDependsOne
  extend TestInjectors

  inject_attr :test_dependency_one, :instance_var
  inject_attr :singleton_dependency, :singleton_var
end

class TestDependsTwo
  extend TestInjectors

  inject_attr :singleton_dependency, :singleton_var
end

class DependencyInjectionTest < Test::Unit::TestCase
  def test_can_locate_dependency
    assert TestContainer.instance.get_dependency(:test_dependency_one)
    assert TestContainer.instance.get_dependency(:singleton_dependency)
  end

  def test_raises_error_when_dependency_cannot_be_found
    assert_raises RuntimeError do
      TestContainer.instance.get_dependency(:non_existent)
    end
  end

  def test_instance_var_dependency_uses_correct_wrapper
    assert_instance_of Proxy::DependencyInjection::InstanceVariableWrapper, TestContainer.instance.dependencies[:test_dependency_one]
  end

  def test_instance_var_dependency_instantiates_correct_class
    assert_instance_of TestDependencyOne, TestContainer.instance.get_dependency(:test_dependency_one)
  end

  def test_instance_var_dependency_defined_by_lambda
    assert_instance_of TestDependencyOne, TestContainer.instance.get_dependency(:test_dependency_two)
  end

  def test_instance_var_dependency_lambda_receives_container_as_parameter
    assert_equal "a_parameter", TestContainer.instance.get_dependency(:test_dependency_two).arg
  end

  def test_singleton_var_dependency_uses_correct_wrapper
    assert_instance_of Proxy::DependencyInjection::SingletonWrapper, TestContainer.instance.dependencies[:singleton_dependency]
  end

  def test_singleton_var_dependency_instantiates_correct_class
    assert_instance_of TestDependencyTwo, TestContainer.instance.get_dependency(:singleton_dependency)
  end

  def test_singleton_var_dependency_defined_by_lambda
    assert_instance_of TestDependencyTwo, TestContainer.instance.get_dependency(:singleton_dependency_two)
  end

  def test_singleton_var_dependency_lambda_receives_container_as_parameter
    assert_equal "a_parameter", TestContainer.instance.get_dependency(:singleton_dependency_two).arg
  end

  def test_instance_var_wiring
    assert_instance_of TestDependencyOne, TestDependsOne.new.instance_var
  end

  def test_singleton_var_wiring
    assert_instance_of TestDependencyTwo, TestDependsOne.new.singleton_var
  end

  def test_instance_var_dependency_is_instantiated_for_every_instance_of_class
    dependency_one_first_instance = TestDependsOne.new.instance_var
    dependency_one_second_instance = TestDependsOne.new.instance_var

    assert dependency_one_first_instance != dependency_one_second_instance
  end

  def test_singleton_var_dependency_is_reused_for_each_instance_of_class
    singleton_dependency_first_instance = TestDependsOne.new.singleton_var
    singleton_dependency_second_instancee = TestDependsOne.new.singleton_var

    assert_equal singleton_dependency_first_instance, singleton_dependency_second_instancee
  end

  def test_singleton_var_dependency_is_reused_for_instances_of_different_classes
    singleton_dependency_first_instance = TestDependsOne.new.singleton_var
    singleton_dependency_second_instancee = TestDependsTwo.new.singleton_var

    assert_equal singleton_dependency_first_instance, singleton_dependency_second_instancee
  end
end
