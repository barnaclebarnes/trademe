module Trademe
  module Authentication
    
    attr_accessor :consumer, :request_token, :access_token
    
    # authorize_url EG: "https://secure.trademe.co.nz/Oauth/Authorize?oauth_token=50277019F3C05999C6599D6801C4607F73"
    def generate_request_token(callback = "oob")
      @request_token = @consumer.get_request_token :oauth_callback => callback

      @request_token.authorize_url
    end

    # example callback: "http://example.com/?oauth_token=0721023CAA76ECF37F4C314DA8A87C38BC&oauth_verifier=F5F194F52CCACC1B9A9F0CE6CB4163E0AB"
    # use oauth_verifier param from URL
    def get_access_token(verifier)
      @access_token = request_token.get_access_token(:oauth_verifier => verifier)
      authorized?
    end
    
    def authorize_from_access(atoken, asecret)
      @access_token = OAuth::AccessToken.new(atoken, asecret)
    end

    def authorized?
      !!consumer && !!access_token
    end
    
  end
end