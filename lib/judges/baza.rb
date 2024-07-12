# frozen_string_literal: true

# Copyright (c) 2024 Yegor Bugayenko
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'typhoeus'
require 'retries'
require 'iri'
require 'loog'
require 'base64'
require_relative '../judges'
require_relative '../judges/elapsed'

# Baza.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class Judges::Baza
  # rubocop:disable Metrics/ParameterLists
  def initialize(host, port, token, ssl: true, timeout: 30, loog: Loog::NULL)
    # rubocop:enable Metrics/ParameterLists
    @host = host
    @port = port
    @ssl = ssl
    @token = token
    @timeout = timeout
    @loog = loog
  end

  def push(name, data, meta)
    id = 0
    hdrs = headers.merge(
      'Content-Type' => 'application/octet-stream',
      'Content-Length' => data.size
    )
    hdrs = hdrs.merge('X-Zerocracy-Meta' => meta.map { |v| Base64.encode64(v).strip }.join(' ')) unless meta.empty?
    elapsed(@loog) do
      ret = with_retries do
        checked(
          Typhoeus::Request.put(
            home.append('push').append(name).to_s,
            body: data,
            headers: hdrs,
            connecttimeout: @timeout,
            timeout: @timeout
          )
        )
      end
      id = ret.body.to_i
      throw :"Pushed #{data.size} bytes to #{@host}, job ID is ##{id}"
    end
    id
  end

  def pull(id)
    data = 0
    elapsed(@loog) do
      Tempfile.open do |file|
        File.open(file, 'wb') do |f|
          request = Typhoeus::Request.new(
            home.append('pull').append("#{id}.fb").to_s,
            headers: headers.merge(
              'Accept' => 'application/octet-stream'
            ),
            connecttimeout: @timeout,
            timeout: @timeout
          )
          request.on_body do |chunk|
            f.write(chunk)
          end
          request.run
          checked(request.response)
        end
        data = File.binread(file)
        throw :"Pulled #{data.size} bytes of job ##{id} factbase at #{@host}"
      end
    end
    data
  end

  # The job with this ID is finished already?
  def finished?(id)
    finished = false
    elapsed(@loog) do
      ret = with_retries do
        checked(
          Typhoeus::Request.get(
            home.append('finished').append(id).to_s,
            headers:
          )
        )
      end
      finished = ret.body == 'yes'
      throw :"The job ##{id} is #{finished ? '' : 'not yet '}finished at #{@host}"
    end
    finished
  end

  # Lock the name.
  def lock(name, owner)
    elapsed(@loog) do
      with_retries do
        checked(
          Typhoeus::Request.get(
            home.append('lock').append(name).add(owner:).to_s,
            headers:
          ),
          302
        )
      end
    end
  end

  # Unlock the name.
  def unlock(name, owner)
    elapsed(@loog) do
      with_retries do
        checked(
          Typhoeus::Request.get(
            home.append('unlock').append(name).add(owner:).to_s,
            headers:
          ),
          302
        )
      end
    end
  end

  def recent(name)
    job = 0
    elapsed(@loog) do
      ret = with_retries do
        checked(
          Typhoeus::Request.get(
            home.append('recent').append("#{name}.txt").to_s,
            headers:
          )
        )
      end
      job = ret.body.to_i
      throw :"The recent \"#{name}\" job's ID is ##{job} at #{@host}"
    end
    job
  end

  def name_exists?(name)
    exists = 0
    elapsed(@loog) do
      ret = with_retries do
        checked(
          Typhoeus::Request.get(
            home.append('exists').append(name).to_s,
            headers:
          )
        )
      end
      exists = ret.body == 'yes'
      throw :"The name \"#{name}\" #{exists ? 'exists' : "doesn't exist"} at #{@host}"
    end
    exists
  end

  private

  def headers
    {
      'User-Agent' => "judges #{Judges::VERSION}",
      'Connection' => 'close',
      'X-Zerocracy-Token' => @token
    }
  end

  def home
    Iri.new('')
      .host(@host)
      .port(@port)
      .scheme(@ssl ? 'https' : 'http')
  end

  def checked(ret, allowed = [200])
    allowed = [allowed] unless allowed.is_a?(Array)
    mtd = (ret.request.original_options[:method] || '???').upcase
    url = ret.effective_url
    log = "#{mtd} #{url} -> #{ret.code}"
    if allowed.include?(ret.code)
      @loog.debug(log)
      return ret
    end
    @loog.debug("#{log}\n  #{(ret.headers || {}).map { |k, v| "#{k}: #{v}" }.join("\n  ")}")
    msg =
      "Invalid response code ##{ret.code} " \
      "at #{mtd} #{url} (#{ret.headers['X-Zerocracy-Flash'].inspect})"
    case ret.code
    when 500
      msg +=
        ', most probably it\'s an internal error on the server, ' \
        'please report this to https://github.com/zerocracy/baza'
    when 503
      msg +=
        ", most probably it's an internal error on the server (#{ret.headers['X-Zerocracy-Failure'].inspect}), " \
        'please report this to https://github.com/yegor256/judges'
    when 404
      msg +=
        ', most probably you are trying to reach a wrong server, which doesn\'t ' \
        'have the URL that it is expected to have'
    end
    raise msg
  end
end
