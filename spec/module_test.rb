module A
  def self.prepended(base)

    if base.respond_to? :foo
      puts ":foo is defined in #{base}"
    else
      puts ":foo is not defined in #{base}"
    end

  end
end

class B
  prepend A

  def self.foo ; end
end

class C
  def self.foo ; end

  prepend A
end
