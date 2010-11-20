#! /usr/bin/env ruby

require 'sinatra'

$: << './lib'
require 'haproxy'

before do
  haproxy = HAProxy.new
  haproxy.parse(File.open("haproxy.csv"))
  @haproxy = haproxy
end

get '/' do
  @title = "HAProxy"
  haml :index
end

get '/:type/:name' do
  @title = params[:name]
  @type = params[:type]
  @data = @haproxy.data_for(@type.to_sym, @title)

  # I know this is not the best way to do it, but does the trick.
  @list_data = {
    :status => {
      :label => "Status: #{@data[:status]}" ,
      :values => {
        :lastchg => "Last status change" ,
        :chkfail => "Failed checks" ,
        :chkdown => "UP &gt; DOWN transitions"
      }
    },
    :sessions => {
      :label => "Sessions",
      :values => {
        :scur => "Current",
        :smax => "Max",
        :slim => "Limit",
        :stot => "Total",
        :rate => "Rate over last second",
        :ratelim => "Rate limit",
        :ratemax => "Max rate",
      }
    },
    :bandwidth => {
      :label => "Bandwith",
      :values => {
        :bin => "IN",
        :bout => "OUT"
      }
    },
    :info => {
      :label => "Proxy information",
      :values => { 
        :iid => "Unique proxy ID",
        :pid => "Process ID",
        :sid => "Service ID"
      }
    }
  }

  haml :server
end
