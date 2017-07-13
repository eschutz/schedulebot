require 'uri'

class InformationController < ApplicationController

  # attr_accessor :background_image

  @@pixabay_client = Pixabay.new
  @@last_img_request = Time.now
  @@background_image = nil
  @@bg_user_url = nil

  def index
    get_background

    if cookies.permanent[:first_visit].nil?
      cookies.permanent[:first_visit] = true
    else
      cookies.permanent[:first_visit] = false
    end
  end

  def getting_started
    get_background

    render 'getting-started'.to_sym
  end

  private

  def get_background

    if params[:new_background] == '1'
      session[:background_url] = nil
    end

    request_time = Time.now
    # Rate limit of 5000 requests per hour = 3600 seconds / 5000 requests
    if ((request_time - @@last_img_request) > (60**2)/5000.0) || !@@background_image
      @@last_img_request = request_time
      bg_request = @@pixabay_client.photos(q: 'landscape', image_type: 'photo', category: 'nature', orientation: 'horizontal', editors_choice: true, order: 'latest')['hits']
      if bg_request
        bg_hit = bg_request[rand(0..bg_request.length)]
        if bg_hit
          @@background_image = bg_hit['webformatURL']
          @@bg_user_url = "https://pixabay.com/en/users/#{bg_hit['user']}-#{bg_hit['user_id']}"
        end
      end
    end

    session[:background_url] ||= @@background_image

  end

end
