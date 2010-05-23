#!/usr/bin/env ruby
require("rbgsl")

#for i in 0...4 do
  c = GSL::Permutation.calloc(10)
  begin
    printf("{");
    c.fprintf(STDOUT, " %u");
    printf(" }\n");
  end while c.next == GSL::SUCCESS
#end
