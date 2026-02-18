require 'swagger_helper'

RSpec.describe 'Contacts API', type: :request do
  path '/contacts/import' do
    post 'Import contacts from CSV' do
      tags 'Contacts'
      description 'Import contacts from a CSV file'
      consumes 'multipart/form-data'
      produces 'application/json'
      security [ Bearer: [] ]

      parameter name: :file, in: :formData, type: :file, required: true, description: 'CSV file to import'

      response '202', 'accepted' do
        schema type: :object, properties: { message: { type: :string } }
        run_test!
      end

      response '422', 'validation failed' do
        schema '$ref' => '#/components/schemas/ErrorResponse'
        run_test!
      end
    end
  end

  path '/contacts/paginated' do
    get 'List contacts (paginated)' do
      tags 'Contacts'
      description 'Retrieve a paginated list of contacts'
      produces 'application/json'
      security [ Bearer: [] ]

      parameter name: :page, in: :query, type: :integer, description: 'Page number', required: false
      parameter name: :per_page, in: :query, type: :integer, description: 'Items per page', required: false

      response '200', 'success' do
        schema type: :object, properties: {
          contacts: { type: :array, items: { '$ref' => '#/components/schemas/Contact' } },
          pagination: {
            type: :object,
            properties: {
              current_page: { type: :integer },
              total_pages: { type: :integer },
              total_count: { type: :integer },
              per_page: { type: :integer }
            }
          }
        }
        run_test!
      end
    end
  end

  path '/contacts/send_emails' do
    post 'Send emails to contacts' do
      tags 'Contacts'
      description 'Send emails to a list of contacts using a specific template'
      consumes 'application/json'
      produces 'application/json'
      security [ Bearer: [] ]

      parameter name: :data, in: :body, schema: {
        type: :object,
        properties: {
          email_template_id: { type: :integer },
          emails: { type: :array, items: { type: :string, format: :email } }
        },
        required: [ 'email_template_id', 'emails' ]
      }

      response '200', 'success' do
        schema type: :object, properties: { message: { type: :string } }
        run_test!
      end

      response '404', 'not found' do
        schema '$ref' => '#/components/schemas/NotFoundErrorResponse'
        run_test!
      end
    end
  end

  path '/contacts' do
    get 'List contacts with filters' do
      tags 'Contacts'
      description 'Retrieve a list of contacts with optional filtering'
      produces 'application/json'
      security [ Bearer: [] ]

      parameter name: :page, in: :query, type: :integer, required: false
      parameter name: :per_page, in: :query, type: :integer, required: false
      parameter name: :bhk_type_id, in: :query, type: :integer, required: false
      parameter name: :furnishing_type_id, in: :query, type: :integer, required: false
      parameter name: :location_id, in: :query, type: :integer, required: false
      parameter name: :property_type_id, in: :query, type: :integer, required: false
      parameter name: :power_backup_type_id, in: :query, type: :integer, required: false

      response '200', 'success' do
        schema type: :object, properties: {
          contacts: { type: :array, items: { '$ref' => '#/components/schemas/Contact' } },
          pagination: {
            type: :object,
            properties: {
              current_page: { type: :integer },
              total_pages: { type: :integer },
              total_count: { type: :integer },
              per_page: { type: :integer }
            }
          }
        }
        run_test!
      end
    end

    post 'Create contact' do
      tags 'Contacts'
      description 'Create a new contact manually'
      consumes 'application/json'
      produces 'application/json'
      security [ Bearer: [] ]

      parameter name: :contact, in: :body, schema: {
        type: :object,
        properties: {
          contact: {
            type: :object,
            properties: {
              first_name: { type: :string },
              last_name: { type: :string },
              email: { type: :string, format: :email },
              phone: { type: :string }
            },
            required: [ 'email' ]
          },
          preference: {
            type: :object,
            properties: {
              bhk_type: { type: :string },
              furnishing_type: { type: :string },
              location: { type: :string },
              property_type: { type: :string },
              power_backup_type: { type: :string }
            }
          }
        },
        required: [ 'contact' ]
      }

      response '201', 'created' do
        schema '$ref' => '#/components/schemas/Contact'
        run_test!
      end

      response '422', 'validation failed' do
        schema '$ref' => '#/components/schemas/ValidationErrorResponse'
        run_test!
      end
    end
  end
end
