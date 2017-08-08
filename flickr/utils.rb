require 'base64'
require 'securerandom'
require 'cgi'
require 'net/http'
require 'date'

# https://stackoverflow.com/questions/4524911/creating-signature-and-nonce-for-oauth-ruby
def sign(key, base_string)
  digest = OpenSSL::Digest.new('sha1')
  hmac = OpenSSL::HMAC.digest(digest, key, base_string)
  Base64.encode64(hmac).chomp.gsub(/\n/, '')
end

def nonce
  SecureRandom.random_number(10000000)
end

def now
  Time.now.to_i
end

def read_access_token(dir)
  File.read("#{dir}/access_token")
end

def read_oauth_token_secret(dir)
  File.read("#{dir}/oauth_token_secret")
end

def call_service(url)
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.ssl_version = 'TLSv1'
  data = http.get(uri.request_uri)
  data.body
end
