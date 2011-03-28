class Dense
  
  def self.pack(obj, objective=nil)
    objective.nil? ? pack_fuzzy(obj) : pack_explicit(obj, objective)
  end
  
  # XXX: It is impossible to use the same :method for both use
  # XXX: cases.
  def self.unpack(obj, objective=nil)
    objective.nil? ? unpack_fuzzy(obj) : unpack_explicit(obj, objective)
  end
  
  def self.suitable?(obj, objective)
    unpack_explicit(pack_explicit(obj, objective), objective) == objective rescue false
  end
  
  def self.convert(obj, from, to)
    pack_explicit(unpack_explicit(obj, from), to)
  end
  
  def self.which(obj)
    find_objective(obj)[:name]
  end

  # TODO
  def self.objective(name, params)
    objective_hash(name, params)
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
      o.each do |key, value|
        case key
        when :method
          value.each do |meth, expected|
            @@index[meth].delete(expected)
            
            if @@index[meth].empty?
              @@index.delete(meth)
              @@index_keys.delete(meth)
            end
          end
        end
      end
      
      @@fallbacks[name] ||= []
      @@fallbacks[name] << o
      
      # Remove unnecessary keys.
      o.delete(:require)
      o.delete(:initialize)
      o.delete(:method)
      
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
    o[:method]     = params[:method].dup      if params.has_key?(:method)
    o[:valid]      = params[:valid].dup       if params.has_key?(:valid)

    o.each do |key, value|
      case key
      when :require
        assert_is_a(key, value, String)
        
        require value
      when :initialize
        assert_is_a(key, value, Proc)
        
        # FIXME: param?
        value.call
      when :method
        assert_is_a(key, value, Hash)
        
        value.each do |meth, expected|
          # We assume, for the sake of simplicity, that Kernel#send accepts
          # only symbols.
          assert_is_a("method", meth, Symbol)
          
          @@index[meth] ||= {}
          @@index[meth][expected] = o
          
          @@index_keys << meth
        end
      end
    end
    
    @@objectives[name] = o
  end
  
  def self.find_objective(obj)
    @@index_keys.each do |key|
      next unless obj.respond_to?(key)
      
      value = obj.send(key)
      
      o = @@index[key][value]
      next if o.nil?

      return o
    end
    
    @@objectives[:default]
  end
  
  def self.pack_fuzzy(obj)
    invoke(:pack, find_objective(obj), obj)
  end

  def self.pack_explicit(obj, name)
    o = (@@objectives[name] || @@objectives[:default])
    invoke(:pack, o, obj)
  end
  
  def self.unpack_explicit(obj, name)
    o = (@@objectives[name] || @@objectives[:default])
    @@fallbacks.has_key?(name) ? unpack_fallback(o, obj) : invoke(:unpack, o, obj)
  end
  
  def self.unpack_fuzzy(obj)
    o = find_objective(obj)
    @@fallbacks.has_key?(name) ? unpack_fallback(o, obj) : invoke(:unpack, o, obj)
  end
  
  def self.unpack_fallback(o, obj)
    name = o[:name]
    
    @@fallbacks[name].each do |fallback|
      begin
        # We do not consider nil to be an incorrect unpack value.
        return invoke(:unpack, o, obj)
      rescue
        o = fallback
        fallback == @@fallbacks[name].last ? raise : next
      end
    end
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