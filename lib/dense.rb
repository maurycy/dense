require 'rubygems'
require 'block_hash'

class Dense
  
  def self.pack(obj, name=nil)
    o = (@@objectives[name] || @@objectives[:default])
    invoke(:pack, o, obj)
  end
  
  def self.unpack(obj, name=nil)
    o = (@@objectives[name] || @@objectives[:default])
    @@fallbacks.has_key?(name) ? unpack_fallback(o, obj) : invoke(:unpack, o, obj)
  end
  
  def self.suitable?(obj, objective)
    unpack(pack(obj, objective), objective) == objective rescue false
  end
  
  def self.convert(obj, from, to)
    pack(unpack(obj, from), to)
  end

  def self.objective(name, params={}, &block)
    objective_hash(name, BlockHash.evaluate(params, &block))
  end
  
protected
  #--
  # This is the only method that does not need massive speed optimization.
  #++
  def self.objective_hash(name, params)
    # Lazy-initialize.
    
    # eg, {:compact => <Objective>}
    @@objectives ||= {}
    
    # eg. {:class => {User => <Objective>}}
    @@index ||= {}
    
    # eg, [:class]
    @@index_keys ||= []
    
    # eg, {:compact => [<Objective>, <Objective>]}
    @@fallbacks ||= {}

    assert_is_a("name", name, Symbol)
    
    if @@objectives.has_key?(name)
      # If there was already an objective defined with this name, it becomes
      # a fallback now.
      o = @@objectives[name]
      
      @@fallbacks[name] ||= []
      @@fallbacks[name] << o
      
      # Remove unnecessary keys.
      o.delete(:require)
      o.delete(:initialize)
      
      @@objectives.delete(o)
    end
    
    assert_has_key(:unpack, params)
    assert_has_key(:pack,   params)
    
    # Explicitly #dup or pass by reference.
    o = {}
    o[:name]       = name
    o[:pack]       = params[:pack]
    o[:unpack]     = params[:unpack]
    o[:require]    = params[:require].dup     if params.has_key?(:require)
    o[:initialize] = params[:initialize].dup  if params.has_key?(:initialize)

    o.each do |key, value|
      case key
      when :require
        assert_is_a(key, value, String)
        
        require value
      when :initialize
        assert_is_a(key, value, Proc)
        
        # FIXME: param?
        value.call
      end
    end
    
    @@objectives[name] = o
  end

  def self.invoke(what, o, obj)
    meth = o[what]
    meth.is_a?(Symbol) ? obj.send(meth) : meth.call(obj)
  end
  
  private
    def self.assert_is_a(key, obj, klass)
      raise(ArgumentError, "#{key} is not #{obj.to_s}") unless obj.is_a?(klass)
    end
  
    def self.assert_has_key(key, hash)
      raise(ArgumentError, "#{key} required") unless hash.has_key?(key)
    end
end

Dense.objective(:default, {
  :require  => "json",
  :pack     => :to_json,
  :unpack   => Proc.new {|obj| JSON.parse(obj) },
})