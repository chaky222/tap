# Configure Spree Preferences
#
# Note: Initializing preferences available within the Admin will overwrite any changes that were made through the user interface when you restart.
#       If you would like users to be able to update a setting with the Admin it should NOT be set here.
#
# Note: If a preference is set here it will be stored within the cache & database upon initialization.
#       Just removing an entry from this initializer will not make the preference value go away.
#       Instead you must either set a new value or remove entry, clear cache, and remove database entry.
#
# In order to initialize a setting do:
# config.setting_name = 'new value'

Spree.config do |config|
  # Example:
  # Uncomment to stop tracking inventory levels in the application
  # config.track_inventory_levels = false
  Spree::Money.class_eval do
    def to_s
      @money.format.gsub(/.00/, "")
      @money.format(:symbol_position => :after,:separator => ' ', :delimiter => '.', :symbol => "грн", :with_currency => false, :no_cents => true)
    end

    def to_html(options = { :html => true })
     to_s
    end
  end 
  
  # Spree::Order.class_eval do
  #   remove_checkout_step :delivery
  #   after_create :select_undefined_shipping

  #   def select_undefined_shipping
  #     # This allows us to skip the :delivery step
  #     shipment = Spree::Shipment.create(order: self, cost: 0, address: bill_address)
  #     shipment.add_shipping_method(Spree::ShippingMethod.undefined_shipping, true)
  #   end
  # end

  # Spree::OrdersController.class_eval do
  #   def update
  #     if @order.contents.update_cart(order_params)
  #       respond_with(@order) do |format|
  #         format.html do
  #           if params.has_key?(:checkout)
  #             # if @order.update_from_params(params, permitted_checkout_attributes, request.headers.env)
  #             #   flash[:alert] =  "asasdasd["+@order.errors.full_messages.join("\n")+"]"
  #             #   unless @order.next
  #             #     flash[:error] = @order.errors.full_messages.join("\n")
  #             #     redirect_to(checkout_state_path(@order.state)) && return
  #             #   end
  #             #   redirect_to checkout_state_path(@order.checkout_steps.first)
  #             # else
  #             #   flash[:error] = @order.errors.full_messages.join("\n")
  #             #   render :edit
  #             # end 
  #             # unless @order.next
  #             #   flash[:error] = @order.errors.full_messages.join("\n")
  #             #   redirect_to(checkout_state_path(@order.state)) && return
  #             # end
              
  #             # let(:flash) { { "notice" => "ok", "foo" => "foo", "bar" => "bar" } }
              

  #             @order.next if @order.cart?
  #             redirect_to checkout_state_path(@order.checkout_steps.first)
  #           else
  #             redirect_to cart_path
  #           end
  #         end
  #       end
  #     else
  #       respond_with(@order)
  #     end
  #   end
  # end
end

Spree.user_class = "Spree::LegacyUser"
