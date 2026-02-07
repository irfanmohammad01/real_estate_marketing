require 'swagger_helper'

RSpec.describe 'Email Templates API', type: :request do
  path '/email_templates' do
    get 'List email templates' do
      tags 'Email Templates'
      description 'Retrieve all email templates in the organization (Org Admin or Org User)'
      produces 'application/json'
      security [ Bearer: [] ]

      response '200', 'success' do
        schema type: :array,
          items: {
            type: :object,
            properties: {
              id: { type: :integer },
              email_type_id: { type: :integer },
              organization_id: { type: :integer },
              name: { type: :string },
              subject: { type: :string },
              preheader: { type: :string },
              from_name: { type: :string },
              from_email: { type: :string },
              reply_to: { type: :string },
              html_body: { type: :string },
              text_body: { type: :string },
              created_at: { type: :string, format: :datetime },
              updated_at: { type: :string, format: :datetime }
            }
          }

        run_test! false
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/ErrorResponse'
        run_test! false
      end

      response '403', 'forbidden' do
        schema '$ref' => '#/components/schemas/ErrorResponse'
        run_test! false
      end
    end

    post 'Create email template' do
      tags 'Email Templates'
      description 'Create a new email template (Org Admin or Org User)'
      consumes 'application/json'
      produces 'application/json'
      security [ Bearer: [] ]

      parameter name: :template_data, in: :body, schema: {
        type: :object,
        properties: {
          email_template: {
            type: :object,
            properties: {
              email_type_id: { type: :integer, example: 1 },
              name: { type: :string, example: 'Welcome Email Template' },
              subject: { type: :string, example: 'Welcome to our platform!' },
              preheader: { type: :string, example: 'Get started with your account' },
              from_name: { type: :string, example: 'Support Team' },
              from_email: { type: :string, example: 'support@company.com' },
              reply_to: { type: :string, example: 'noreply@company.com' },
              html_body: { type: :string, example: '<h1>Welcome!</h1><p>Thanks for joining us.</p>' },
              text_body: { type: :string, example: 'Welcome! Thanks for joining us.' }
            },
            required: [ 'email_type_id', 'name', 'subject' ]
          }
        }
      }

      response '201', 'created' do
        schema type: :object,
          properties: {
            message: { type: :string }
          }

        run_test! false
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/ErrorResponse'
        run_test! false
      end

      response '403', 'forbidden' do
        schema '$ref' => '#/components/schemas/ErrorResponse'
        run_test! false
      end

      response '422', 'validation failed' do
        schema '$ref' => '#/components/schemas/ErrorResponse'
        run_test! false
      end
    end
  end

  path '/email_templates/{id}' do
    parameter name: :id, in: :path, type: :integer, description: 'Template ID'

    get 'Show email template' do
      tags 'Email Templates'
      description 'Retrieve details of a specific email template (Org Admin or Org User)'
      produces 'application/json'
      security [ Bearer: [] ]

      response '200', 'success' do
        schema type: :object,
          properties: {
            id: { type: :integer },
            email_type_id: { type: :integer },
            organization_id: { type: :integer },
            name: { type: :string },
            subject: { type: :string },
            preheader: { type: :string },
            from_name: { type: :string },
            from_email: { type: :string },
            reply_to: { type: :string },
            html_body: { type: :string },
            text_body: { type: :string },
            created_at: { type: :string, format: :datetime },
            updated_at: { type: :string, format: :datetime }
          }

        run_test! false
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/ErrorResponse'
        run_test! false
      end

      response '403', 'forbidden' do
        schema '$ref' => '#/components/schemas/ErrorResponse'
        run_test! false
      end

      response '404', 'not found' do
        schema '$ref' => '#/components/schemas/ErrorResponse'
        run_test! false
      end
    end

    patch 'Update email template' do
      tags 'Email Templates'
      description 'Update email template details (Org Admin or Org User)'
      consumes 'application/json'
      produces 'application/json'
      security [ Bearer: [] ]

      parameter name: :template_data, in: :body, schema: {
        type: :object,
        properties: {
          email_template: {
            type: :object,
            properties: {
              name: { type: :string },
              subject: { type: :string },
              preheader: { type: :string },
              from_name: { type: :string },
              from_email: { type: :string },
              reply_to: { type: :string },
              html_body: { type: :string },
              text_body: { type: :string }
            }
          }
        }
      }

      response '200', 'success' do
        schema type: :object,
          properties: {
            message: { type: :string }
          }

        run_test! false
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/ErrorResponse'
        run_test! false
      end

      response '403', 'forbidden' do
        schema '$ref' => '#/components/schemas/ErrorResponse'
        run_test! false
      end

      response '422', 'validation failed' do
        schema '$ref' => '#/components/schemas/ErrorResponse'
        run_test! false
      end
    end
  end

  path '/email_templates/by_type' do
    get 'Get templates by type' do
      tags 'Email Templates'
      description 'Retrieve email templates filtered by type key (Org Admin or Org User)'
      produces 'application/json'
      security [ Bearer: [] ]

      parameter name: :key, in: :query, type: :string, description: 'Email type key', required: true, example: 'welcome_email'

      response '200', 'success' do
        schema type: :array,
          items: {
            type: :object,
            properties: {
              id: { type: :integer },
              email_type_id: { type: :integer },
              organization_id: { type: :integer },
              name: { type: :string },
              subject: { type: :string },
              created_at: { type: :string, format: :datetime }
            }
          }

        run_test! false
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/ErrorResponse'
        run_test! false
      end

      response '403', 'forbidden' do
        schema '$ref' => '#/components/schemas/ErrorResponse'
        run_test! false
      end
    end
  end
end
