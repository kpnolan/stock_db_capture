# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

module Tags
  RUBY_FILES = FileList['**/*.rb'].exclude("pkg")
end

namespace "tags" do
  task :emacs => Tags::RUBY_FILES do
    puts "Making Emacs TAGS file"
    sh "xctags -e #{Tags::RUBY_FILES}", :verbose => false
  end
end

task :tags => ["tags:emacs"]
