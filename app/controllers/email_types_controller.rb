class EmailTypesController < ApplicationController
  before_action -> { authorize_org_member!("ORG_ADMIN") }

  def create
    email_type = EmailType.new(email_type_params)

    if email_type.save
      render json: email_type, status: :created
    else
      render json: { errors: email_type.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def index
    render json: EmailType.all
  end


  private

  def email_type_params
    params.require(:email_type).permit(:key, :description)
  end
end
