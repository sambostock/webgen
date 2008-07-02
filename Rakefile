# -*- ruby -*-

# load all optional developer libraries
begin
  require 'rubygems'
  require 'rake/gempackagetask'
rescue LoadError
end

begin
  require 'rubyforge'
rescue LoadError
end

begin
  require 'rcov/rcovtask'
rescue LoadError
end

begin
  require 'dcov'
rescue LoadError
end

require 'fileutils'
require 'rake/clean'
require 'rake/testtask'
require 'rake/packagetask'
require 'rake/rdoctask'

require './lib/webgen/version'
require './lib/webgen/page'

# End user tasks ################################################################

task :default => :test

desc "Install using setup.rb"
task :install do
  ruby "setup.rb config"
  ruby "setup.rb setup"
  ruby "setup.rb install"
end

task :clobber do
  ruby "setup.rb clean"
end

desc "Build the whole user documentation"
task :doc => [:rdoc, :htmldoc]

desc "Generate the HTML documentation"
task :htmldoc do
  $:.unshift('./lib')
  require 'webgen/website'
  Webgen::Website.new('.') do |config|
    config['sources'] = [['/', "Webgen::Source::FileSystem", 'doc'],
                         ['/', "Webgen::Source::FileSystem", 'misc', 'default.*'],
                         ['/', "Webgen::Source::FileSystem", 'misc', 'htmldoc.metainfo'],
                         ['/', "Webgen::Source::FileSystem", 'misc', 'htmldoc.virtual'],
                         ['/', "Webgen::Source::FileSystem", 'misc', 'images/**/*']]
    config['output'] = ['Webgen::Output::FileSystem', 'htmldoc']
  end.render
end
CLOBBER << ['webgen.cache', 'htmldoc']

rd = Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'htmldoc/rdoc'
  rdoc.title = 'webgen'
  rdoc.main = 'Webgen'
  rdoc.options << '--line-numbers' << '--inline-source' << '--promiscuous'
  rdoc.rdoc_files.include('lib/**/*.rb')
end

tt = Rake::TestTask.new do |test|
  test.libs << 'test'
end

# Release tasks and development tasks ############################################

namespace :dev do

  SUMMARY = 'webgen is a fast, powerful, and extensible static website generator.'
  DESCRIPTION = <<EOF
webgen is used to generate static websites from templates and content
files (which can be written in a markup language). It can generate
dynamic content like menus on the fly and comes with many powerful
extensions.
EOF

  begin
    REL_PAGE = Webgen::Page.from_data(File.read('website/src/news/release_' + Webgen::VERSION.split('.').join('_') + '.page'))
  rescue
    puts 'NO RELEASE NOTES/CHANGES FILE'
  end

  PKG_FILES = FileList.new([
                            'Rakefile',
                            'setup.rb',
                            'VERSION',
                            'AUTHORS',
                            'THANKS',
                            'COPYING',
                            'GPL',
                            'bin/webgen',
                            'data/**/*'
                            'doc/**/*',
                            'lib/**/*.rb',
                            'man/man1/webgen.1',
                            'misc/**/*'
                            'test/test_*.rb',
                            'test/helper.rb',
                           ]) do |fl|
    fl.exclude('data/**/.gitignore')
  end

  CLOBBER << "VERSION"
  file 'VERSION' do
    puts "Generating VERSION file"
    File.open('VERSION', 'w+') {|file| file.write(Webgen::VERSION + "\n")}
  end

  Rake::PackageTask.new('webgen', Webgen::VERSION) do |pkg|
    pkg.need_tar = true
    pkg.need_zip = true
    pkg.package_files = PKG_FILES
  end

  if defined? Gem
    spec = Gem::Specification.new do |s|

      #### Basic information
      s.name = 'webgen'
      s.version = Webgen::VERSION
      s.summary = SUMMARY
      s.description = DESCRIPTION

      #### Dependencies, requirements and files

      s.files = PKG_FILES.to_a
      s.add_dependency('cmdparse', '~> 2.0.0')
      s.add_dependency('maruku', '>= 0.5.6')
      s.add_dependency('facets', '>= 2.4.1')
      s.add_dependency('rake')

      s.require_path = 'lib'

      s.executables = ['webgen']
      s.default_executable = 'webgen'

      #### Documentation

      s.has_rdoc = true
      s.rdoc_options = ['--line-numbers', '--inline-source', '--promiscuous', '--main', 'Webgen']

      #### Author and project details

      s.author = 'Thomas Leitner'
      s.email = 't_leitner@gmx.at'
      s.homepage = "http://webgen.rubyforge.org"
      s.rubyforge_project = 'webgen'
    end

    Rake::GemPackageTask.new(spec) do |pkg|
      pkg.need_zip = true
      pkg.need_tar = true
    end

  end

  desc "Upload webgen documentation to Rubyforge homepage"
  task :publish_doc => [:doc] do
    sh "rsync -avc htmldoc/ gettalong@rubyforge.org:/var/www/gforge-projects/webgen/documentation/#{(Webgen::VERSION.split('.')[0..-2] + ['x']).join('.')}"
  end

  desc 'Release webgen version ' + Webgen::VERSION
  task :release => [:clobber, :package, :publish_files, :publish_doc]

  desc 'Announce webgen version ' + Webgen::VERSION
  task :announce => [:clobber, :doc, :publish_doc, :post_news]

  if defined? RubyForge
    desc "Upload the release to Rubyforge"
    task :publish_files => [:package] do
      print 'Uploading files to Rubyforge...'
      $stdout.flush

      rf = RubyForge.new
      rf.configure
      rf.login

      rf.userconfig["release_notes"] = REL_PAGE.blocks['notes'].content
      rf.userconfig["release_changes"] = REL_PAGE.blocks['changes'].content
      rf.userconfig["preformatted"] = false

      files = %w[.gem .tgz .zip].collect {|ext| "pkg/webgen-#{Webgen::VERSION}" + ext}

      rf.add_release('webgen', 'webgen', Webgen::VERSION, *files)
      puts 'done'
    end

    desc 'Post announcement to rubyforge.'
    task :post_news do
      print 'Posting announcement to Rubyforge ...'
      $stdout.flush
      rf = RubyForge.new
      rf.configure
      rf.login

      rf.post_news('webgen', "webgen #{Webgen::VERSION} released", REL_PAGE.blocks['notes'].content)
      puts "done"
    end
  end

  desc 'Generates the webgen website'
  task :website do
    $:.unshift('./lib')
    require 'webgen/website'
    Webgen::Website.new('website') do |config|
      config['sources'] += [['/documentation/', 'Webgen::Source::FileSystem', '../doc'],
                            ['/', "Webgen::Source::FileSystem", '../misc', 'default.css'],
                            ['/', "Webgen::Source::FileSystem", '../misc', 'images/**/*']]
    end.render
  end
  CLOBBER << ['website/webgen.cache', 'website/out']

  desc "Upload the webgen website to Rubyforge"
  task :publish_website => [:website] do
    sh "rsync -avc --exclude 'documentation/0.5.x' --exclude 'documentation/0.4.x' --exclude 'wiki' website_html/ gettalong@rubyforge.org:/var/www/gforge-projects/webgen/"
  end


  desc "Run the tests one by one to check for missing deps"
  task :test_isolated do
    Dir['test/test_*'].each do |file|
      if !system("ruby -Ilib:test #{file} -vs &> /dev/null")
        puts "Problem with test" + " "*5 + file
      end
    end
  end

  if defined? Rcov
    Rcov::RcovTask.new do |rcov|
      rcov.libs << 'test'
    end
  end

  if defined? Dcov
    desc "Analyze documentation coverage"
    task :dcov do
      class Dcov::Analyzer; def generate; end; end
      Dcov::Analyzer.new(:path => Dir.getwd, :files => Dir.glob('lib/**'))
    end
  end

end

task :clobber => ['dev:clobber']

# Helper methods ###################################################################
