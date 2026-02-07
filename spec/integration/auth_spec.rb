require 'swagger_helper'

RSpec.describe 'Authentication API', type: :request do
  path '/auth/super/login' do
    post 'Super User Login' do
      tags 'Authentication'
      description 'Authenticate as a super user and receive a JWT token'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :credentials, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string, format: :email, example: 'super@admin.com' },
          password: { type: :string, example: 'SecureP@ss123' }
        },
        required: [ 'email', 'password' ]
      }

      response '200', 'successful login' do
        schema type: :object,
          properties: {
            token: { type: :string, description: 'JWT Bearer token' },
            super_user: {
              type: :object,
              properties: {
                id: { type: :integer },
                email: { type: :string }
              }
            }
          }

        run_test! false
      end

      response '401', 'invalid credentials' do
        schema type: :object,
          properties: {
            error: { type: :string, example: 'Invalid email or password' }
          }

        run_test! false
      end
    end
  end

  path '/auth/login' do
    post 'User Login' do
      tags 'Authentication'
      description 'Authenticate as a regular user and receive a JWT token'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :credentials, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string, format: :email, example: 'user@organization.com' },
          password: { type: :string, example: 'SecureP@ss123' }
        },
        required: [ 'email', 'password' ]
      }

      response '200', 'successful login' do
        schema type: :object,
          properties: {
            token: { type: :string, description: 'JWT Bearer token' },
            user: {
              type: :object,
              properties: {
                id: { type: :integer },
                email: { type: :string },
                full_name: { type: :string },
                role: { type: :string }
              }
            }
          }

        run_test! false
      end

      response '401', 'invalid credentials' do
        schema type: :object,
          properties: {
            error: { type: :string, example: 'Invalid email or password' }
          }

        run_test! false
      end
    end
  end
end
