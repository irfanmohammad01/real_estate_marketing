require 'swagger_helper'

RSpec.describe 'Organizations API', type: :request do
  path '/organizations' do
    get 'List all organizations' do
      tags 'Organizations'
      description 'Retrieve a list of all organizations (Super User only)'
      produces 'application/json'
      security [ Bearer: [] ]

      response '200', 'success' do
        schema type: :array,
          items: { '$ref' => '#/components/schemas/Organization' }

        run_test! false
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/UnauthorizedErrorResponse'
        run_test! false
      end
    end

    post 'Create organization with first user' do
      tags 'Organizations'
      description 'Create a new organization and its first admin user in one atomic operation (Super User only)'
      consumes 'application/json'
      produces 'application/json'
      security [ Bearer: [] ]

      parameter name: :organization_data, in: :body, schema: {
        type: :object,
        properties: {
          organization: {
            type: :object,
            properties: {
              name: { type: :string, example: 'Acme Real Estate' },
              description: { type: :string, example: 'Leading real estate company' }
            },
            required: [ 'name' ]
          },
          user: {
            type: :object,
            properties: {
              full_name: { type: :string, example: 'John Doe' },
              email: { type: :string, format: :email, example: 'admin@acme.com' },
              phone: { type: :string, example: '+1234567890' }
            },
            required: [ 'full_name', 'email' ]
          }
        },
        required: [ 'organization', 'user' ]
      }

      response '201', 'created' do
        schema type: :object,
          properties: {
            message: { type: :string },
            organization: { '$ref' => '#/components/schemas/Organization' },
            user: {
              type: :object,
              properties: {
                id: { type: :integer },
                full_name: { type: :string },
                email: { type: :string },
                phone: { type: :string },
                status: { type: :string },
                role: { type: :string }
              }
            }
          }

        run_test! false
      end

      response '400', 'bad request - missing parameters' do
        schema '$ref' => '#/components/schemas/ErrorResponse'
        run_test! false
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/UnauthorizedErrorResponse'
        run_test! false
      end

      response '422', 'validation failed' do
        schema '$ref' => '#/components/schemas/ValidationErrorResponse'
        run_test! false
      end
    end
  end

  path '/organizations/{id}' do
    parameter name: :id, in: :path, type: :integer, description: 'Organization ID'

    get 'Show organization' do
      tags 'Organizations'
      description 'Retrieve details of a specific organization (Super User only)'
      produces 'application/json'
      security [ Bearer: [] ]

      response '200', 'success' do
        schema '$ref' => '#/components/schemas/Organization'
        run_test! false
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/UnauthorizedErrorResponse'
        run_test! false
      end

      response '404', 'not found' do
        schema '$ref' => '#/components/schemas/NotFoundErrorResponse'
        run_test! false
      end
    end

    patch 'Update organization' do
      tags 'Organizations'
      description 'Update organization details (Super User only)'
      consumes 'application/json'
      produces 'application/json'
      security [ Bearer: [] ]

      parameter name: :organization_data, in: :body, schema: {
        type: :object,
        properties: {
          organization: {
            type: :object,
            properties: {
              name: { type: :string },
              description: { type: :string }
            }
          }
        }
      }

      response '200', 'success' do
        schema '$ref' => '#/components/schemas/Organization'
        run_test! false
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/UnauthorizedErrorResponse'
        run_test! false
      end

      response '422', 'validation failed' do
        schema '$ref' => '#/components/schemas/ValidationErrorResponse'
        run_test! false
      end
    end

    delete 'Soft delete organization' do
      tags 'Organizations'
      description 'Soft delete an organization (Super User only)'
      produces 'application/json'
      security [ Bearer: [] ]

      response '200', 'success' do
        schema type: :object,
          properties: {
            message: { type: :string }
          }
        run_test! false
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/UnauthorizedErrorResponse'
        run_test! false
      end
    end
  end

  path '/organizations/{id}/restore' do
    parameter name: :id, in: :path, type: :integer, description: 'Organization ID'

    post 'Restore deleted organization' do
      tags 'Organizations'
      description 'Restore a soft-deleted organization (Super User only)'
      produces 'application/json'
      security [ Bearer: [] ]

      response '200', 'success' do
        schema type: :object,
          properties: {
            message: { type: :string }
          }
        run_test! false
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/UnauthorizedErrorResponse'
        run_test! false
      end

      response '404', 'not found' do
        schema '$ref' => '#/components/schemas/NotFoundErrorResponse'
        run_test! false
      end
    end
  end
end
