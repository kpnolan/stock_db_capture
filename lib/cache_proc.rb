# Module: CacheProc
#
# Very simple set of functions to cheaply add object and method caching to any class.
#
# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

module CacheProc

  def self.included(other)
    other.instance_eval { @tcache = Hash.new }
  end

  def cache(*objs)
    objs.map do |obj|
      @tcache.has_key?(obj) ? @tcache[obj] : @tcache[obj] = obj
    end
  end

  def cache_proc(key, promise)
    @tcache.has_key?(key) ? @tcache[key] : @tcache[key] = promise.call(key)
  end

  def cache_block(key, &promise)
    @tcache.has_key?(key) ? @tcache[key] : @tcache[key] = promise.call(key)
  end
end
