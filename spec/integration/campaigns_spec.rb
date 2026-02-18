require 'swagger_helper'

RSpec.describe 'Campaigns API', type: :request do
  path '/campaigns' do
    get 'List campaigns' do
      tags 'Campaigns'
      description 'Retrieve all campaigns for the organization'
      produces 'application/json'
      security [ Bearer: [] ]

      response '200', 'success' do
        schema type: :array, items: { '$ref' => '#/components/schemas/Campaign' }
        run_test!
      end
    end

    post 'Create campaign' do
      tags 'Campaigns'
      description 'Create a new campaign & send emails to audience'
      consumes 'application/json'
      produces 'application/json'
      security [ Bearer: [] ]

      parameter name: :campaign, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          email_template_id: { type: :integer },
          audience_id: { type: :integer },
          scheduled_at: { type: :string, format: :date_time, nullable: true }
        },
        required: [ 'name', 'email_template_id', 'audience_id' ]
      }

      response '201', 'created' do
        schema '$ref' => '#/components/schemas/Campaign'
        run_test!
      end

      response '422', 'validation failed' do
        schema '$ref' => '#/components/schemas/ValidationErrorResponse'
        run_test!
      end
    end
  end

  path '/campaigns/{id}' do
    parameter name: :id, in: :path, type: :integer

    put 'Update campaign' do
      tags 'Campaigns'
      description 'Update a campaign'
      consumes 'application/json'
      produces 'application/json'
      security [ Bearer: [] ]

      parameter name: :campaign, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          email_template_id: { type: :integer },
          scheduled_at: { type: :string, format: :date_time }
        }
      }

      response '200', 'success' do
        schema '$ref' => '#/components/schemas/Campaign'
        run_test!
      end

      response '422', 'validation failed' do
        schema '$ref' => '#/components/schemas/ValidationErrorResponse'
        run_test!
      end
    end

    delete 'Delete campaign' do
      tags 'Campaigns'
      description 'Delete a campaign'
      produces 'application/json'
      security [ Bearer: [] ]

      response '200', 'success' do
        schema type: :object, properties: { message: { type: :string } }
        run_test!
      end
    end
  end

  path '/campaigns/send_email_to_audience' do
    post 'Send email to audience' do
      tags 'Campaigns'
      description 'Manually trigger email sending to an audience'
      consumes 'application/json'
      produces 'application/json'
      security [ Bearer: [] ]

      parameter name: :data, in: :body, schema: {
        type: :object,
        properties: {
          audience_id: { type: :integer },
          email_template_id: { type: :integer },
          scheduled_at: { type: :string, format: :date_time, nullable: true }
        },
        required: [ 'audience_id', 'email_template_id' ]
      }

      response '200', 'success' do
        schema type: :object, properties: {
          message: { type: :string },
          count: { type: :integer }
        }
        run_test!
      end

      response '404', 'not found' do
        schema type: :object, properties: { error: { type: :string } }
        run_test!
      end
    end
  end
end
