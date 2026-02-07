require 'swagger_helper'

RSpec.describe 'Users API', type: :request do
  path '/users' do
    get 'List users in organization' do
      tags 'Users'
      description 'Retrieve all users in the current organization (Org Admin only)'
      produces 'application/json'
      security [ Bearer: [] ]

      response '200', 'success' do
        schema type: :array,
          items: { '$ref' => '#/components/schemas/User' }

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

    post 'Create new user' do
      tags 'Users'
      description 'Create a new user in the organization (Org Admin only). Password is auto-generated and sent via email.'
      consumes 'application/json'
      produces 'application/json'
      security [ Bearer: [] ]

      parameter name: :user_data, in: :body, schema: {
        type: :object,
        properties: {
          full_name: { type: :string, example: 'Jane Smith' },
          email: { type: :string, format: :email, example: 'jane@organization.com' },
          phone: { type: :string, example: '+1234567890' }
        },
        required: [ 'full_name', 'email' ]
      }

      response '201', 'created' do
        schema '$ref' => '#/components/schemas/User'
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

  path '/users/{id}' do
    parameter name: :id, in: :path, type: :integer, description: 'User ID'

    get 'Show user details' do
      tags 'Users'
      description 'Retrieve details of a specific user in the organization (Org Admin only)'
      produces 'application/json'
      security [ Bearer: [] ]

      response '200', 'success' do
        schema '$ref' => '#/components/schemas/User'
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

    patch 'Update user' do
      tags 'Users'
      description 'Update user details (Org Admin only)'
      consumes 'application/json'
      produces 'application/json'
      security [ Bearer: [] ]

      parameter name: :user_data, in: :body, schema: {
        type: :object,
        properties: {
          full_name: { type: :string },
          phone: { type: :string }
        }
      }

      response '200', 'success' do
        schema '$ref' => '#/components/schemas/User'
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
