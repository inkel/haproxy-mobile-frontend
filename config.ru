$: << '.'
require 'rubygems' if RUBY_VERSION < '1.9.2'
require 'sinatra'
require 'monitor'
run Sinatra::Application
