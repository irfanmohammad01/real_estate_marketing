class ContactsController < ApplicationController
  # before_action :authorize_org_member!

  # def create
  #   contact = Contact.new(contact_params)
  #   contact.organization_id = current_user.organization_id

  #   ActiveRecord::Base.transaction do
  #     contact.save!

  #     if params[:preference].present?
  #       Preference.create!(
  #         contacts_id: contact.id,
  #         bhk_type_id: params[:preference][:bhk_type_id],
  #         furnishing_type_id: params[:preference][:furnishing_type_id]
  #       )
  #     end
  #   end

  #   render json: contact, status: :created
  # rescue ActiveRecord::RecordInvalid => e
  #   render json: { error: e.message }, status: :unprocessable_entity
  # end

  # private

  # def contact_params
  #   params.require(:contact).permit(
  #     :first_name,
  #     :last_name,
  #     :email,
  #     :phone
  #   )
  # end
end
