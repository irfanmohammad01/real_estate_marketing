class EmailTemplatesController < ApplicationController
  before_action -> { authorize_org_member!("ORG_ADMIN", "ORG_USER") }
  before_action :set_email_template, only: [ :show, :update ]

  def create
    template = EmailTemplate.new(email_template_params)
    template.organization_id = current_user.organization_id

    if template.save
      render json: { message: "Email template created successfully" }, status: :created
    else
      render json: { errors: template.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def index
    templates = EmailTemplate.where(
      organization_id: current_user.organization_id
    )
    render json: templates
  end

  def show
    render json: @email_template
  end

  def by_type
    templates = EmailTemplate
      .joins(:email_type)
      .where(
        organization_id: current_user.organization_id,
        email_types: { key: params[:key] }
      )

    render json: templates
  end

  def update
    if @email_template.update(email_update_template_params)
      render json: { message: "Email template updated successfully" }, status: :ok
    else
      render json: { errors: @email_template.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_email_template
    @email_template = EmailTemplate.find_by!(
      id: params[:id],
      organization_id: current_user.organization_id
    )
  end

  def email_update_template_params
    params.require(:email_template).permit(
      :name,
      :subject,
      :preheader,
      :from_name,
      :from_email,
      :reply_to,
      :html_body,
      :text_body
    )
  end


  def email_template_params
    params.require(:email_template).permit(
      :email_type_id,
      :name,
      :subject,
      :preheader,
      :from_name,
      :from_email,
      :reply_to,
      :html_body,
      :text_body
    )
  end
end
