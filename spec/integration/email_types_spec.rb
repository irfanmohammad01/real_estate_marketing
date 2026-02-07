require 'swagger_helper'

RSpec.describe 'Email Types API', type: :request do
  path '/email_types' do
    get 'List all email types' do
      tags 'Email Types'
      description 'Retrieve all email types (Org Admin only)'
      produces 'application/json'
      security [ Bearer: [] ]

      response '200', 'success' do
        schema type: :array,
          items: {
            type: :object,
            properties: {
              id: { type: :integer },
              key: { type: :string },
              description: { type: :string },
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

    post 'Create email type' do
      tags 'Email Types'
      description 'Create a new email type (Org Admin only)'
      consumes 'application/json'
      produces 'application/json'
      security [ Bearer: [] ]

      parameter name: :email_type_data, in: :body, schema: {
        type: :object,
        properties: {
          email_type: {
            type: :object,
            properties: {
              key: { type: :string, example: 'welcome_email' },
              description: { type: :string, example: 'Welcome email for new users' }
            },
            required: [ 'key' ]
          }
        }
      }

      response '201', 'created' do
        schema type: :object,
          properties: {
            id: { type: :integer },
            key: { type: :string },
            description: { type: :string },
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

      response '422', 'validation failed' do
        schema '$ref' => '#/components/schemas/ErrorResponse'
        run_test! false
      end
    end
  end
end
