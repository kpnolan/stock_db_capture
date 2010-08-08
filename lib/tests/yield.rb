def sync_each(list)
  until list.empty?
    yield list.pop
  end
end


l = [1,2,3,4,5,6,7,8,9,0]

sync_each(l) { |el| p el }
