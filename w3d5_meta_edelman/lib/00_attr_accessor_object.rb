class AttrAccessorObject
  def self.my_attr_accessor(*names)
    names.each do |atr|
      define_method(atr) do
        instance_variable_get("@#{atr}")
      end

      define_method("#{atr}=") do |value|
        instance_variable_set("@#{atr}", value)
      end
    end 
  end
end
