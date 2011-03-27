$:.unshift "../lib"

require 'rubygems'
require 'ruby-prof'
require 'dense'

ITERATIONS = 10_000

Dense.objective(:default, {
  :pack   => :to_json,
  :unpack => Proc.new {|obj| JSON.parse(obj) }
})

tmp = {
  :id => 7,
  :login => 'maurycy',
  :password => 'abc123',
  :password_confirmation => 'abc123',
  :email => 'maurycy@g.pl'
}

# Profile the code
result = RubyProf.profile do
  ITERATIONS.times { Dense.pack(tmp) }
end

# Print a graph profile to text
printer = RubyProf::GraphPrinter.new(result)
printer.print(STDOUT, 0)