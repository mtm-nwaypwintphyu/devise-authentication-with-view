require 'rails_helper'

RSpec.describe Users::UserUsecase do
  let(:valid_params) { { first_name: Faker::Name.first_name, last_name: Faker::Name.last_name, email: Faker::Internet.unique.email } }
  let(:user) { create(:user) }

  describe '#update' do
    context 'when form is valid and service updates user successfully' do
      it 'returns updated user with status :updated' do
        usecase = described_class.new(valid_params)

        response = usecase.update(user)
        expect(response[:status]).to eq(:updated)
        updated_user = response[:user]
        expect(updated_user.first_name).to eq(valid_params[:first_name])
        expect(updated_user.last_name).to eq(valid_params[:last_name])
        expect(updated_user.email).to eq(valid_params[:email])
      end
    end

    context 'when form is valid but service updates user unsuccessfully' do
      before do
        allow_any_instance_of(Users::UserService).to receive(:update).and_wrap_original do |m, *args|
          user.assign_attributes(valid_params)
          user.email = nil
          user.valid?
          { user: user, status: :unprocessable_entity }
        end
      end

      it 'returns unprocessible entity with user errors' do
        usecase = described_class.new(valid_params)
        response = usecase.update(user)

        expect(response[:status]).to eq(:unprocessable_entity)
        expect(response[:user]).to eq(user)
        expect(response[:errors]).to include("Email can't be blank")
      end
    end

    context 'when an exception is raised during update' do
      it "rescues the error and returns the error message with status :unprocessable_entity" do
        usecase = described_class.new(valid_params)

        allow_any_instance_of(Users::UserService).to receive(:update).and_raise(StandardError, "Something wrong")

        response = usecase.update(user)
        expect(response[:status]).to eq(:unprocessable_entity)
        expect(response[:errors]).to eq("Something wrong")
        expect(response[:user]).to be_a(Users::UserForm)
      end
    end
  end

  describe '#destroy' do
    context 'when service delete user successfully' do
      it 'return true' do
        usecase = described_class.new(valid_params)

        response = usecase.destroy(user.id)
        expect(response).to be_truthy
      end
    end

    context 'when service fail user deletion' do
      it 'return false' do
        usecase = described_class.new(valid_params)

        allow_any_instance_of(Users::UserService).to receive(:destroy).with(user.id).and_return(false)

        response = usecase.destroy(user.id)
        expect(response).to be_falsey
      end
    end

    context 'when an exception is raised during deletion' do
      it "rescues the error and returns false" do
        usecase = described_class.new(valid_params)

        allow_any_instance_of(Users::UserService).to receive(:destroy).and_raise(StandardError, "Something wrong")

        response = usecase.destroy(user)
        expect(response).to be_falsey
      end
    end
  end
end
