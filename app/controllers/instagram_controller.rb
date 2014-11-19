class InstagramController < ApplicationController
  
  layout 'option1'
  
  CALLBACK_URL = "http://0.0.0.0:3000/oauth/callback"
  
  def index 
    @instagram_object = Instagram.client_id
    @instagram = Instagram
  end
  
  def connect
    redirect_to Instagram.authorize_url(:redirect_uri => CALLBACK_URL)
  end
  
  def callback
    response = Instagram.get_access_token(params[:code], :redirect_uri => CALLBACK_URL)
    session[:access_token] = response.access_token
    redirect_to nav_url
  end
  
  def search
    @client = Instagram.client(:access_token => session[:access_token])
    @html = "<h1>Search for tags, get tag info and get media by tag</h1>"
    @media_items = []
    @tags = []
    times = 0
    
    if request.post?
      params[:tag] = params[:tag].sub(' ','_')
      
    
      unless params[:tag].empty?
        @tags = @client.tag_search(params[:tag])
      end
      
      unless @tags.empty? 
        response = @client.tag_recent_media(@tags[0].name)
        for media_item in response
          if media_item.location
      	    @media_items << media_item
    			end
      	end
	
  	    @next_max_tag_id = response.pagination.next_max_tag_id
        @next_url = response.pagination.next_url
        @min_tag_id = response.pagination.min_tag_id
      
        while @media_items.size < 500 && times < 50 do
           response = @client.tag_recent_media(@tags[0].name,:max_id => @next_max_tag_id)
              for media_item in response
                if media_item.location
            	    @media_items << media_item
            	   # puts media_item.link
            	   # puts media_item.tags
          			end
            	end

            #puts response.pagination.next_max_tag_id
            #puts @media_items.size
            

      	    @next_max_tag_id = response.pagination.next_max_tag_id
            @next_url = response.pagination.next_url
            @min_tag_id = response.pagination.min_tag_id
            
            times = times + 1
            
            
        end
     
      else
        flash[:error] = "Invalid Hashtag"
        redirect_to root_url
      end
     
    end
  end
  
  def more
    @media_items = []
      response = Instagram.get(params[:next_url])
  
      for media_item in response
        if media_item.location
    	#@client.tag_recent_media(tag.name).each_with_index do |media_item,index|
    	    @media_items << media_item
    	    #puts media_item.inspect
    			#media_item.location.inspect
  			end
    	end
    
      @max_tag_id = response.pagination.next_url.split('&')[1].split('=')[1]
      @next_url = response.pagination.next_url
      @min_tag_id = response.pagination.min_tag_id

      respond_to do |format|
        format.js {}
      end
      
  end
  
  
end
