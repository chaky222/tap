module Spree
  class OrdersController < Spree::StoreController
    before_action :check_authorization
    rescue_from ActiveRecord::RecordNotFound, with: :render_404
    helper 'spree/products', 'spree/orders'

    respond_to :html

    before_action :assign_order_with_lock, only: :update
    skip_before_action :verify_authenticity_token, only: [:populate]

    def show
      @order = Order.includes(line_items: [variant: [:option_values, :images, :product]], bill_address: :state, ship_address: :state).find_by_number!(params[:id])
    end

    def update
      # order_params[:bill_address_attributes][:checkout] = 'zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz'
      @params = params
      puts "\n\n\n update params=[#{@params.to_json}]\n\n\n"
      if @order.contents.update_cart(order_params)
        respond_with(@order) do |format|
          format.html do            
            if params.has_key?(:checkout)             
                @order.restart_checkout_flow
                @order.next if @order.cart?
                # params[:order].delete :line_items_attributes
                params_new = JSON.load(params.to_json)
                params_new["order"].delete("shipments_attributes")
                # flash[:error] = "params333=["+params.to_json+"]"
                # redirect_to(checkout_state_path(@order.state)) && return
                # flash[:error] = "params_new222=["+params_new.to_json+"] params=["+params.to_json+"]"
               
                # @order.update_line_item_prices!
                # @order.create_tax_charge!
                # @order.persist_user_address!
                # @order.update_line_item_prices
                # if @order.shipments.any? && !@order.completed?
                #   @order.shipments.destroy_all
                #   # @order.update_column(:shipment_total, 0)
                # end
                # puts "\n\n\n\n permitted_checkout_attributes=#{permitted_checkout_attributes.to_json} \n\n\n" and return
                if @order.update_from_params(params_new, permitted_checkout_attributes, request.headers.env)
                  if spree_current_user

                  else
                    flash[:error] = "Необходимо авторизоваться чтобы оформить заказ."
                    store_location
                    redirect_to login_path && return
                  end
                  unless @order.next
                    flash[:error] = "ERRORS111=["+@order.errors.full_messages.join("\n")+"]"
                    redirect_to(checkout_state_path(@order.state)) && return
                  end
                  # @order.apply_free_shipping_promotions
                  params_new = JSON.load(params.to_json)
                  params_new["order"].delete("bill_address_attributes")
                  params_new["order"].delete("line_items_attributes")
                  # flash[:error] = "state=["+@order.state+"] params_new555=["+params_new.to_json+"] params=["+params.to_json+"]"
                  # redirect_to(checkout_state_path(@order.state)) && return
                  if @order.update_from_params(params_new,permitted_checkout_attributes, request.headers.env)
                    unless @order.next
                      flash[:error] = "ERRORS222=["+@order.errors.full_messages.join("\n")+"]"
                      redirect_to(checkout_state_path(@order.state)) && return
                    end
                    # flash[:error] = "done1 order=["+@order.to_json+"] params_new=["+params_new.to_json+"]"
                    # redirect_to(checkout_state_path(@order.state)) && return
                  else
                    flash[:error] = "ERRORS333=["+@order.state+"]"
                    redirect_to(checkout_state_path(@order.state)) && return
                  end;
                end
                # redirect_to(checkout_state_path(@order.state))
                 # redirect_to cart_path
                redirect_to checkout_state_path(@order.checkout_steps.first)             
            else
              puts "\n\n\n\n params=[#{params.to_json}] \n\n\n has_key=[#{params.has_key?(:basket_auth_btn)}] \n\n\n"
              if params.has_key?(:basket_auth_btn)
                puts "\n\n\n client_store_ref_in_path=[#{client_store_ref_in_path}]\n\n\n"
                redirect_to client_store_ref_in_path
              else
                redirect_to cart_path
              end
            end
          end
        end
      else
        respond_with(@order)
      end
    end

    # Shows the current incomplete order from the session
    def edit      
      @order = current_order || Order.incomplete.
                                  includes(line_items: [variant: [:images, :option_values, :product]]).
                                  find_or_initialize_by(guest_token: cookies.signed[:guest_token])
      @order.save! unless @order.id
      puts "\n\n\n edit guest_token=[#{cookies.signed[:guest_token]}] order=[#{@order.to_json}] \n\n\n"
      associate_user      

      @order.assign_default_addresses!
      puts "\n\n\n\n edit assign_default_addresses good bill_address=[#{@order.bill_address}]\n\n\n\n";
      @order.bill_address = User.find(1).bill_address.try(:clone) unless @order.bill_address
      puts "\n\n\n\n edit bill_address good\n\n\n\n";
      
      
      # if @order.next
      #   puts "\n\n\n\n edit order next good\n\n\n\n";

      # else
      #   puts "\n\n\n\n edit order next bad\n\n\n\n";
      # end
      
      # @order.create_proposed_shipments     
      # @order.refresh_shipment_rates
      # @order.set_shipments_cost
      # @order.apply_free_shipping_promotions

      if (@order[:state] == 'cart')
        if @order.next
          puts "\n\n\n\n edit order next cart good\n\n\n\n";
        else
          puts "\n\n\n\n edit order next cart bad\n\n\n\n";
        end
      else
        puts "\n\n\n\n edit order state not eq cart\n\n\n\n";
      end   
      @order.ship_address = User.find(1).ship_address.try(:clone) unless @order.ship_address
      # @updating_params =  {order: { bill_address_attributes: [{city: "Kriviy Rih", country_id: 229, state_id: 2975, zipcode: "50015"} ] } }
      
      # 
      @order.shipments = Spree::Stock::Coordinator.new(@order).shipments unless @order.shipments&.count > 0
      @order.refresh_shipment_rates
      @order.set_shipments_cost
      @order.apply_free_shipping_promotions
      @order.available_payment_methods
      # @updating_params ||= {}
      # @updating_params[:order] ||= {bill_address_attributes:[{city: "Kriviy Rih", country_id: 229, state_id: 2975, zipcode: "50015"}]}
      # @updating_params[:order][:bill_address_attributes] ||= [{}]
      # @updating_params[:order][:bill_address_attributes].first[:city]       = "Kriviy Rih"
      # @updating_params[:order][:bill_address_attributes].first[:country_id] = "229"
      # @updating_params[:order][:bill_address_attributes].first[:state_id]   = "2975"
      # @updating_params[:order][:bill_address_attributes].first[:zipcode]    = "50015"
      # if @order.update_from_params(@updating_params, permitted_checkout_attributes, request.headers.env)

      # end
      # @order.bill_address = user.bill_address.try(:clone)
      # @order.create_proposed_shipments     
      # @order.refresh_shipment_rates
      # @order.set_shipments_cost
      # @order.apply_free_shipping_promotions
       puts "\n\n\n edit shipments=["+@order.shipments.to_json+"]\n\n\n\n"
       puts "\n\n\n edit shipment_total=["+@order.shipment_total.to_json+"]\n\n\n\n"
       # puts "\n\n\n edit client_store_ref_path=[#{client_store_ref_path}] \n\n\n"
       # puts "\n\n\n edit packages=["+Spree::Stock::Coordinator.packages.to_json+"]\n\n\n\n"
      # flash[:error] = "order1112=["+@order.to_json+"]\n\n available_payment_methods=["+@order.available_payment_methods.to_json+"]"
    end

    # Adds a new item to the order (creating a new order if none already exists)
    def populate
      order    = current_order(create_order_if_necessary: true)
      variant  = Spree::Variant.find(params[:variant_id])
      quantity = params[:quantity].to_i
      options  = params[:options] || {}

      # 2,147,483,647 is crazy. See issue #2695.
      if quantity.between?(1, 2_147_483_647)
        begin
          order.contents.add(variant, quantity, options)
        rescue ActiveRecord::RecordInvalid => e
          error = e.record.errors.full_messages.join(", ")
        end
      else
        error = Spree.t(:please_enter_reasonable_quantity)
      end

      if error
        flash[:error] = error
        redirect_back_or_default(spree.root_path)
      else
        respond_with(order) do |format|
          format.html { redirect_to cart_path }
        end
      end
    end

    def populate_redirect
      flash[:error] = Spree.t(:populate_get_error)
      redirect_to('/cart')
    end

    def empty
      if @order = current_order
        @order.empty!
      end

      redirect_to spree.cart_path
    end

    def accurate_title
      if @order && @order.completed?
        Spree.t(:order_number, number: @order.number)
      else
        Spree.t(:shopping_cart)
      end
    end

    def check_authorization
      order = Spree::Order.find_by_number(params[:id]) || current_order

      if order
        authorize! :edit, order, cookies.signed[:guest_token]
      else
        authorize! :create, Spree::Order
      end
    end

    private

      def order_params
        if params[:order]
          params[:order].permit(*permitted_order_attributes)
        else
          {}
        end
      end

      def assign_order_with_lock
        @order = current_order(lock: true)
        unless @order
          flash[:error] = Spree.t(:order_not_found)
          redirect_to root_path and return
        end
      end
  end
end
