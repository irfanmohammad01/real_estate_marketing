# spec/integration/users_spec.rb
path '/api/users' do
  get 'List users' do
    tags 'Users'
    produces 'application/json'

    response '200', 'users found' do
      run_test!
    end
  end
end
