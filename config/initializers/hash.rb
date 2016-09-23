class Hash
  def map_keys(&block)
    self.inject({}) do |ret, e|
      k,v = e
      ret[block.call(k)] = v
      ret
    end
  end

  def map_values(&block)
    self.inject({}) do |ret, e|
      k,v = e
      ret[k] = block.call(v)
      ret
    end
  end
end
