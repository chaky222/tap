# This migration comes from spree (originally 20130207155350)
class AddOrderSelectedPayment < ActiveRecord::Migration[4.2]
  def change
    add_column :spree_orders, :selected_payment_method, :integer, default: 2
  end
end
