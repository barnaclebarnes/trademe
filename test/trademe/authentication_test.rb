require File.dirname(__FILE__) + "/../test_helper.rb"

class AuthenticationTest < Test::Unit::TestCase
  
  context "a new gateway" do
    
    setup do
      @callback = "http://example.com"
      @key = "1234"
      @secret = "5678"
      @gateway = ::Trademe::Gateway.new(:consumer_key => @key, :consumer_secret => @secret)
    end
    
    context "with an access token that's already been generated" do
      setup do
        @access_token  = "test_access_token"
        @access_secret = "test_access_secret"
      end
      
      should "authorize correctly" do
        @gateway.authorize_from_access(@access_token, @access_secret)
        
        assert @gateway.authorized?
      end
      
    end
    
    context "when generating a request token" do
      setup do
        success_response = Net::HTTPSuccess.new('foo', 200, 'Success')
        success_response.stubs(:body).returns("oauth_token=12345&oauth_token_secret=67890&oauth_callback_confirmed=true")
        
        Net::HTTP.any_instance.expects(:request).at_least_once.returns(success_response)
      end
      
      should "give you the URL to go to" do
        assert_equal @gateway.generate_request_token(@callback), "https://secure.trademe.co.nz/Oauth/Authorize?oauth_token=12345"
      end
    
      context "when requesting access token" do
        setup do
          @gateway.generate_request_token(@callback)
          
          success_response = Net::HTTPSuccess.new('foo', 200, 'Success')
          success_response.stubs(:body).returns("oauth_token=54321&oauth_token_secret=09876")

          Net::HTTP.any_instance.expects(:request).at_least_once.returns(success_response)
        end
      
        should "return true (verified)" do
          response = @gateway.get_access_token("12345")
          assert_equal @gateway.access_token.to_query, "oauth_token=54321&oauth_secret=09876"
          
          assert response == @gateway.authorized?
        end
        
        context "sending an API request" do
          setup do
            response = @gateway.get_access_token("12345")
            
            success_response = Net::HTTPSuccess.new('foo', 200, 'Success')
            success_response.stubs(:body).returns(open_mock("listing_search.json"))
            @gateway.consumer.expects(:request).at_least_once.returns(success_response)
          end
          
          should "use authorized client to send request" do
            assert @gateway.authorized?
            
            res = @gateway.search "property/residential", :search_string => "nice"
            setup = Yajl::Parser.new.parse(open_mock("listing_search.json"))["List"].map{|hash| Trademe::Models::Listing.new(hash) }

            assert res.map{|l| l.id } == setup.map{|l| l.id }
          end
        end
        
      end
    end
        
  end
  
end