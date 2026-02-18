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
              error: { type: :string },
              message: { type: :string },
              errors: {
                type: :object,
                description: 'Error messages organized by field or category'
              }
            }
          },
          UnauthorizedErrorResponse: {
            type: :object,
            properties: {
              error: { type: :string, example: 'Unauthorized' },
              message: { type: :string, example: 'You need to sign in or sign up before continuing.' }
            }
          },
          ForbiddenErrorResponse: {
            type: :object,
            properties: {
              error: { type: :string, example: 'Forbidden' },
              message: { type: :string, example: 'You are not authorized to perform this action.' }
            }
          },
          NotFoundErrorResponse: {
            type: :object,
            properties: {
              error: { type: :string, example: 'Not Found' },
              message: { type: :string, example: 'Resource not found.' }
            }
          },
          ValidationErrorResponse: {
            type: :object,
            properties: {
              error: { type: :string, example: 'Validation Failed' },
              errors: { type: :array, items: { type: :string } }
            }
          },
          ServerErrorResponse: {
            type: :object,
            properties: {
              error: { type: :string, example: 'Internal Server Error' },
              message: { type: :string }
            }
          },
          RateLimitErrorResponse: {
            type: :object,
            properties: {
              error: { type: :string, example: 'Too Many Requests' },
              message: { type: :string, example: 'Rate limit exceeded. Try again in 60 seconds.' }
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
              role_name: { type: :string },
              organization_name: { type: :string },
              organization_id: { type: :integer },
              role_id: { type: :integer },
              created_at: { type: :string, format: :datetime },
              updated_at: { type: :string, format: :datetime }
            }
          },
          Audience: {
            type: :object,
            properties: {
              id: { type: :integer },
              name: { type: :string },
              bhk_type_id: { type: :integer, nullable: true },
              furnishing_type_id: { type: :integer, nullable: true },
              location_id: { type: :integer, nullable: true },
              property_type_id: { type: :integer, nullable: true },
              power_backup_type_id: { type: :integer, nullable: true },
              organization_id: { type: :integer },
              created_at: { type: :string, format: :datetime },
              updated_at: { type: :string, format: :datetime }
            }
          },
          Contact: {
            type: :object,
            properties: {
              id: { type: :integer },
              first_name: { type: :string },
              last_name: { type: :string },
              email: { type: :string, format: :email },
              phone: { type: :string },
              organization_id: { type: :integer },
              created_at: { type: :string, format: :datetime },
              updated_at: { type: :string, format: :datetime },
              preferences: {
                type: :array,
                items: {
                  type: :object,
                  properties: {
                    id: { type: :integer },
                    bhk_type_id: { type: :integer },
                    furnishing_type_id: { type: :integer },
                    location_id: { type: :integer },
                    property_type_id: { type: :integer },
                    power_backup_type_id: { type: :integer }
                  }
                }
              }
            }
          },
          Campaign: {
            type: :object,
            properties: {
              id: { type: :integer },
              name: { type: :string },
              email_template_id: { type: :integer },
              schedule_type_id: { type: :integer },
              organization_id: { type: :integer },
              status: { type: :string },
              scheduled_at: { type: :string, format: :datetime },
              created_at: { type: :string, format: :datetime },
              updated_at: { type: :string, format: :datetime }
            }
          }
        }
      }
    }
  }

  # Specify the format of the output Swagger file
  config.openapi_format = :yaml
end
