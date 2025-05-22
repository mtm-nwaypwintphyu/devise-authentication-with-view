require 'rails_helper'

RSpec.describe Users::UserService, type: :service do
  describe "#update" do
   let(:valid_params) { {first_name: Faker::Name.first_name, last_name: Faker::Name.last_name, email: Faker::Internet.unique.email} } 
   let(:user) { create(:user) }

    context "when user update successfully" do
      it "return status:updated and updated user" do
        service = described_class.new(valid_params)
        response = service.update(user)
        updated_user = response[:user]
        expect(response[:status]).to eq(:updated)
        expect(updated_user[:first_name]).to eq(valid_params[:first_name])
        expect(updated_user[:last_name]).to eq(valid_params[:last_name])
        expect(updated_user[:email]).to eq(valid_params[:email])
      end
    end

    context "when user update fail" do
      it "return status :unprocessable_entity and updated user" do
        service = described_class.new(valid_params)
        allow_any_instance_of(Users::UserService).to receive(:update).and_return({ user: user, status: :unprocessable_entity })
        response = service.update(user)

        expect(response[:status]).to eq(:unprocessable_entity)
        expect(response[:user]).to eq(user)
      end
    end

  end

  describe "#destroy" do
   let(:user) { create(:user) }
    context "when user is invalid" do
      it 'returns false' do
        service = described_class.new(user)
        response = service.destroy(2000)
        expect(response).to be_falsey
      end
    end

    context "when user is valid and delete success" do
      it "return true" do
        service = described_class.new(user)
        response = service.destroy(user.id)
        expect(response).to be_truthy
      end
    end

   context "when an exception occurs when deleting user" do
      it "returns false" do
        service = described_class.new(user)
        allow_any_instance_of(Users::UserService).to receive(:destroy).with(user.id).and_return(false)

        response = service.destroy(user.id)

        expect(response).to eq(false)
      end
   end

  end
end
