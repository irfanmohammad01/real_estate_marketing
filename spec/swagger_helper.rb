# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  config.openapi_root = Rails.root.join('swagger').to_s

  # Define one or more Swagger documents and provide global metadata for each one
  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'Real Estate Marketing API',
        version: 'v1',
        description: 'API for managing real estate organizations, users, and email marketing templates. Supports multi-tenant architecture with organization-based access control.'
      },
      paths: {},
      servers: [
        {
          url: 'http://localhost:3000',
          description: 'Development server'
        },
        {
          url: 'https://{defaultHost}',
          variables: {
            defaultHost: {
              default: 'api.example.com'
            }
          },
          description: 'Production server'
        }
      ],
      components: {
        securitySchemes: {
          Bearer: {
            type: :http,
            scheme: :bearer,
            bearerFormat: 'JWT',
            description: 'JWT Bearer token authentication. Use super user token for admin endpoints, regular user token for organization-specific endpoints.'
          }
        },
        schemas: {
          ErrorResponse: {
            type: :object,
            properties: {
              errors: {
                type: :object,
                description: 'Error messages organized by field or category'
              }
            }
          },
          Organization: {
            type: :object,
            properties: {
              id: { type: :integer },
              name: { type: :string },
              description: { type: :string },
              created_at: { type: :string, format: :datetime },
              updated_at: { type: :string, format: :datetime },
              deleted_at: { type: :string, format: :datetime, nullable: true }
            }
          },
          User: {
            type: :object,
            properties: {
              id: { type: :integer },
              full_name: { type: :string },
              email: { type: :string, format: :email },
              phone: { type: :string },
              status: { type: :string },
              organization_id: { type: :integer },
              role_id: { type: :integer }
            }
          }
        }
      }
    }
  }

  # Specify the format of the output Swagger file
  config.openapi_format = :yaml
end
