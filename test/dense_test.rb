require 'rubygems'
require 'test/unit'

class DenseTest < Test::Unit::TestCase

  def setup
    dense_reload
  end

  def test_objective_argument_error
    assert_raises(ArgumentError) { Dense.objective(:default, {}) }
  end
  
  def test_pack
    assert_nothing_raised { Dense.pack(v) }
  end
  
  def test_pack_default
    assert_equal Dense.pack(v), Dense.pack(v, :default)
  end
  
  def test_pack_explicit
    dense_objective_compact do
      assert_equal v, Marshal.load(Dense.pack(v, :compact))
    end
  end
  
  def test_pack_explicit_missing
    dense_objective_compact do
      assert_equal      Dense.pack(v, :default), Dense.pack(v, :missing)
      assert_not_equal  Dense.pack(v, :default), Dense.pack(v, :compact)
    end
  end
  
  def test_pack_overwrite
    dense_objective_compact do
      assert_equal Marshal.dump(v), Dense.pack(v, :compact)
      
      Dense.objective(:compact, {
        :pack   => :to_json,
        :unpack => Proc.new {|obj| JSON.parse(obj) }
      })
      
      assert_equal v.to_json, Dense.pack(v, :compact)
    end
  end
  
  def test_suitable?
    assert ! Dense.suitable?(v, :default)
    
    dense_objective_exceptions do
      assert ! Dense.suitable?(v, :creepy)
    end
  end
  
  def test_convert
    dense_objective_transparent do
      dense_objective_compact do
        densed    = Dense.pack(v, :compact)
        converted = Dense.convert(densed, :compact, :transparent)
        
        assert_equal v, Dense.unpack(converted, :transparent)
      end
    end
  end
  
  def test_unpack_exact
    dense_objective_compact do
      assert_equal v, Dense.unpack(Dense.pack(v, :compact), :compact)
    end
  end
  
  def test_unpack_fallback
    dense_objective_compact do
      Dense.objective(:compact, {
        :pack   => :to_json,
        :unpack => Proc.new {|obj| JSON.parse(obj) } 
      })
      
      assert_equal JSON.parse(v.to_json), Dense.unpack(v.to_json)
    end
  end
  
protected
  def v
    {1 => 2}
  end
  
  def dense_objective_hash
    Dense.objective(:hash, {
      :method   => {:class => Hash},
      :pack     => Proc.new {|obj| Marshal.dump(obj) },
      :unpack   => Proc.new {|obj| Marshal.load(obj) }
    })
    
    if block_given?
      yield
      dense_reload
    end
  end
  
  def dense_objective_compact
    Dense.objective(:compact, {
      :pack    => Proc.new {|obj| Marshal.dump(obj) },
      :unpack  => Proc.new {|obj| Marshal.load(obj) }
    })
    
    if block_given?
      yield
      dense_reload
    end
  end
  
  def dense_objective_exceptions
    Dense.objective(:exceptions, {
      :pack     => Proc.new {|obj| raise(NotImplemented) },
      :unpack   => Proc.new {|obj| raise(NotImplemented) }
    })
      
    if block_given?
      yield
      dense_reload
    end
  end
  
  def dense_objective_transparent
    Dense.objective(:transparent) do |o|
      o.pack    Proc.new {|obj| obj}
      o.unpack  Proc.new {|obj| obj}
    end
    
    if block_given?
      yield
      dense_reload
    end
  end
  
private
  def dense_reload
    Object.send(:remove_const, :Dense) if Object.const_defined?(:Dense)
    
    load '../lib/dense.rb'

    Dense.objective(:default, {
      :require  => "json",
      :pack     => :to_json,
      :unpack   => Proc.new {|obj| JSON.parse(obj) },
    })
  end
end
