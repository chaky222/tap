module Spree
  class ClientSiteController < Spree::StoreController
    before_action :store_ref, only: [:store_ref_in, :store_ref_out]

    def store_ref   
      session["spree_user_return_to"] = nil
      if request.referer.length > 5
        r = URI(request.referer)        
        session["spree_user_return_to"] = request.referer if r.host == request.host
      end      
    end

    def store_ref_in  
      redirect_to spree.login_path and return
    end

    def store_ref_out
      redirect_to spree.logout_path and return
    end
  end
end