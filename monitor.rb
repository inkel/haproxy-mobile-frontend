#! /usr/bin/env ruby

require 'sinatra'

$: << './lib'
require 'haproxy'

before do
  @haproxy = HAProxy.connect 'haproxy'
end

get '/' do
  @title = "HAProxy"
  haml :index
end

get '/errors' do
  @errors = @haproxy.errors
  haml :errors
end

get '/sessions' do
  @sessions = @haproxy.sessions
  haml :sessions
end

get %r{/(frontend|backend|server)/([\w]+)} do |type, name|
  @proxy = @haproxy.proxy_data(type, name)
  @title = "#{type}: #{name}"
  haml type.to_sym
end
