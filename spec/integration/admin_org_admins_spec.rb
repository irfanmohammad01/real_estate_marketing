require 'swagger_helper'

RSpec.describe 'Admin - Org Admins API', type: :request do
  path '/admin/org_admins' do
    post 'Create organization admin' do
      tags 'Admin'
      description 'Create a new organization admin user (Super User only)'
      consumes 'application/json'
      produces 'application/json'
      security [ Bearer: [] ]

      parameter name: :admin_data, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: {
              organization_id: { type: :integer, example: 1 },
              full_name: { type: :string, example: 'Admin User' },
              email: { type: :string, format: :email, example: 'admin@organization.com' },
              password: { type: :string, example: 'SecureP@ss123' },
              phone: { type: :string, example: '+1234567890' }
            },
            required: [ 'organization_id', 'full_name', 'email', 'password' ]
          }
        }
      }

      response '201', 'created' do
        schema '$ref' => '#/components/schemas/User'
        run_test! false
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/ErrorResponse'
        run_test! false
      end

      response '422', 'validation failed' do
        schema '$ref' => '#/components/schemas/ErrorResponse'
        run_test! false
      end
    end

    patch 'Update organization admin' do
      tags 'Admin'
      description 'Update organization admin details (Super User only)'
      consumes 'application/json'
      produces 'application/json'
      security [ Bearer: [] ]

      parameter name: :admin_data, in: :body, schema: {
        type: :object,
        properties: {
          id: { type: :integer, description: 'User ID to update' },
          user: {
            type: :object,
            properties: {
              full_name: { type: :string },
              phone: { type: :string }
            }
          }
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

      response '422', 'validation failed' do
        schema '$ref' => '#/components/schemas/ErrorResponse'
        run_test! false
      end
    end
  end
end
