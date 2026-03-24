require 'swagger_helper'

RSpec.describe 'Audiences API', type: :request do
  path '/audiences' do
    get 'List audiences' do
      tags 'Audiences'
      description 'List all audiences for the current organization'
      produces 'application/json'
      security [ Bearer: [] ]

      response '200', 'success' do
        schema type: :array, items: { '$ref' => '#/components/schemas/Audience' }
        run_test!
      end
    end

    post 'Create audience' do
      tags 'Audiences'
      description 'Create a new audience'
      consumes 'application/json'
      produces 'application/json'
      security [ Bearer: [] ]

      parameter name: :audience, in: :body, schema: {
        type: :object,
        properties: {
          audience: {
            type: :object,
            properties: {
              name: { type: :string },
              bhk_type_id: { type: :integer, nullable: true },
              furnishing_type_id: { type: :integer, nullable: true },
              location_id: { type: :integer, nullable: true },
              property_type_id: { type: :integer, nullable: true },
              power_backup_type_id: { type: :integer, nullable: true }
            },
            required: [ 'name' ]
          }
        },
        required: [ 'audience' ]
      }

      response '201', 'created' do
        schema '$ref' => '#/components/schemas/Audience'
        run_test!
      end

      response '422', 'validation failed' do
        schema '$ref' => '#/components/schemas/ValidationErrorResponse'
        run_test!
      end
    end
  end

  path '/audiences/{id}' do
    parameter name: :id, in: :path, type: :integer

    get 'Show audience' do
      tags 'Audiences'
      description 'Retrieves an audience'
      produces 'application/json'
      security [ Bearer: [] ]

      response '200', 'success' do
        schema '$ref' => '#/components/schemas/Audience'
        run_test!
      end

      response '404', 'not found' do
        schema '$ref' => '#/components/schemas/NotFoundErrorResponse'
        run_test!
      end
    end

    put 'Update audience' do
      tags 'Audiences'
      description 'Updates an audience'
      consumes 'application/json'
      produces 'application/json'
      security [ Bearer: [] ]

      parameter name: :audience, in: :body, schema: {
        type: :object,
        properties: {
          audience: {
            type: :object,
            properties: {
              name: { type: :string },
              bhk_type_id: { type: :integer, nullable: true },
              furnishing_type_id: { type: :integer, nullable: true },
              location_id: { type: :integer, nullable: true },
              property_type_id: { type: :integer, nullable: true },
              power_backup_type_id: { type: :integer, nullable: true }
            }
          }
        },
        required: [ 'audience' ]
      }

      response '200', 'success' do
        schema '$ref' => '#/components/schemas/Audience'
        run_test!
      end

      response '422', 'validation failed' do
        schema '$ref' => '#/components/schemas/ValidationErrorResponse'
        run_test!
      end
    end

    delete 'Delete audience' do
      tags 'Audiences'
      description 'Soft deletes an audience'
      produces 'application/json'
      security [ Bearer: [] ]

      response '200', 'success' do
        schema type: :object, properties: { message: { type: :string } }
        run_test!
      end
    end
  end

  path '/audiences/{id}/restore' do
    parameter name: :id, in: :path, type: :integer

    post 'Restore audience' do
      tags 'Audiences'
      description 'Restores a soft-deleted audience'
      produces 'application/json'
      security [ Bearer: [] ]

      response '200', 'success' do
        schema type: :object, properties: {
          message: { type: :string },
          audience: { '$ref' => '#/components/schemas/Audience' }
        }
        run_test!
      end

      response '404', 'not found' do
        schema '$ref' => '#/components/schemas/NotFoundErrorResponse'
        run_test!
      end
    end
  end
end
