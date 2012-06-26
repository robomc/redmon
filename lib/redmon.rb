require 'rubygems'
require 'active_support/core_ext'
require 'eventmachine'
require 'haml'
require 'redis'
require 'sinatra/base'
require 'mongrel'

module Redmon
  extend self

  attr_reader :opts

  @opts = {
    :web_interface => ['0.0.0.0', 4567],
    :redis_url     => 'redis://127.0.0.1:6379',
    :namespace     => 'redmon',
    :worker        => true,
    :poll_interval => 10
  }

  def run(opts={})
    @opts.merge! opts
    start_em
  rescue Exception => e
    log "!!! Redmon has shit the bed, restarting... #{e.message}"
    sleep(1); run(opts)
  end

  def start_em
    EM.run do
      trap 'TERM', &method(:shutdown)
      trap 'INT',  &method(:shutdown)
      start_app    if opts[:web_interface]
      start_worker if opts[:worker]
    end
  end

  def start_app
    Redmon::App.set :port, @opts[:web_interface][1]
    Redmon::App.run!
    log "listening on http##{opts[:web_interface].join(':')}"
  rescue Exception => e
    log "Can't start Redmon::App. port in use?  Error #{e}"
  end

  def start_worker
    Worker.new.run!
  end

  def shutdown
    EM.stop
  end

  def log(msg)
    puts "[#{Time.now.strftime('%y-%m-%d %H:%M:%S')}] #{msg}"
  end

  def [](option)
    opts[option]
  end

end

require 'redmon/redis'
require 'redmon/helpers'
require 'redmon/app'
require 'redmon/worker'
