# frozen_string_literal: true

# BigBlueButton open source conferencing system - http://www.bigbluebutton.org/.
#
# Copyright (c) 2018 BigBlueButton Inc. and by respective authors (see below).
#
# This program is free software; you can redistribute it and/or modify it under the
# terms of the GNU Lesser General Public License as published by the Free Software
# Foundation; either version 3.0 of the License, or (at your option) any later
# version.
#
# BigBlueButton is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License along
# with BigBlueButton; if not, see <http://www.gnu.org/licenses/>.

require 'net/http'
require 'uri'
require 'json'

module AuthValues
  extend ActiveSupport::Concern

  def perform_lookup(auth)
    # try and find the user's name through the Lookup API
    uri = URI.parse("https://www.lookup.cam.ac.uk/api/v1/person/crsid/#{auth['uid']}?fetch=email")
    # make the connection
    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = 5
    http.open_timeout = 5
    http.use_ssl = true
    # create a request object
    request = Net::HTTP::Get.new(uri.request_uri)
    # set the JSON header
    request["Accept"] = "application/json"
    # send the request and return it
    http.request(request)
  end

  def set_lookup_values(u, response, auth)
    # did the response fail? fall back to defaults
    # overwrite name and email each time
    if response.code != "200"
      u.name = auth['uid']
      u.email = ""
    else
      json_response = JSON.parse(response.body)["result"]
      u.name = json_response["person"]["visibleName"]
      email_test = json_response["attributes"][0]
      u.email = email_test.present? email_test["value"] : ""
    end
    u.username = auth['uid'] unless u.username
    u.image = ""
  end
  
  # Provider attributes.
  def auth_name(auth)
    case auth['provider']
    when :office365
      auth['info']['display_name']
    else
      auth['info']['name']
    end
  end

  def auth_username(auth)
    case auth['provider']
    when :google
      auth['info']['email'].split('@').first
    when :bn_launcher
      auth['info']['username']
    else
      auth['info']['nickname']
    end
  end

  def auth_email(auth)
    auth['info']['email']
  end

  def auth_image(auth)
    case auth['provider']
    when :twitter
      auth['info']['image'].gsub("http", "https").gsub("_normal", "")
    when :ldap
      return auth['info']['image'] if auth['info']['image']&.starts_with?("http")
      ""
    else
      auth['info']['image']
    end
  end

  def auth_roles(user, auth)
    unless auth['info']['roles'].nil?
      roles = auth['info']['roles'].split(',')

      role_provider = auth['provider'] == "bn_launcher" ? auth['info']['customer'] : "greenlight"
      roles.each do |role_name|
        role = Role.find_by(provider: role_provider, name: role_name)
        user.role = role if !role.nil? && !user.has_role?(role_name)
      end
    end
  end
end
