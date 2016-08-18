class InstagramController < ApplicationController
  
  layout 'option1'
  
  CALLBACK_URL = "http://www.rflresearchtool.com/oauth/callback"
  #CALLBACK_URL = "http://0.0.0.0:3000/oauth/callback"
  
  def index 
    @instagram_object = Instagram.client_id
    @instagram = Instagram
  end
  
  def privacy 
    pdf_filename = File.join(Rails.root, "public/PrivacyPolicy.pdf")
    send_file(pdf_filename, :filename => "your_document.pdf", :disposition => 'inline', :type => "application/pdf")
  end
  
  def connect
    redirect_to Instagram.authorize_url(:redirect_uri => CALLBACK_URL, :scope => 'basic')
  end
  
  def disconnect
    session[:access_token] = nil
    redirect_to root_url
  end
  
  def callback
    @response = Instagram.get_access_token(params[:code], :redirect_uri => CALLBACK_URL)
    session[:access_token] = @response.access_token
    redirect_to nav_url
  end
  
  def search
    @client = Instagram.client(:access_token => session[:access_token])
    puts @client
    @html = "<h1>Search for tags, get tag info and get media by tag</h1>"
    @media_items = []
    @tags = []
    @tag = ''
    @next_max_tag_id = 0
    times = 0
    
    if request.post?
      params[:tag] = params[:tag].sub(' ','')
      #params[:tag] = params[:tag].sub('_','')

      unless params[:tag].empty?
        @tags = @client.tag_search(params[:tag])
      end
      
      unless @tags.empty? 
        @tag = @tags[0].name
        puts "tag: #{@tag}"
        
        response = @client.tag_recent_media(@tag)
        puts response.inspect
        
        for media_item in response
          puts ''
          puts media_item
          puts ''
          if media_item.location
      	    @media_items << media_item
    			end
        end
	
  	    @next_max_tag_id = response.pagination.next_max_tag_id
        @next_url = response.pagination.next_url
        @min_tag_id = response.pagination.min_tag_id

=begin      
        while @media_items.size < 25 && times < 100 do
           response = @client.tag_recent_media(@tag,:max_id => @next_max_tag_id)
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
        #puts @media_items.size
=end     
        
      else
        flash[:error] = "Invalid Hashtag"
        redirect_to root_url
      end
     
    end
  end
  
  def more
     @next_tag_id = params[:next_max_tag_id]
     @num_pics = params[:num_pics]
     @tag = params[:tag]
     #puts  @tag
     @media_items = []

     response = Instagram.client.tag_recent_media(@tag,:max_id => @next_tag_id)
     puts response
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

      respond_to do |format|
        format.js {}
      end

  end

end
