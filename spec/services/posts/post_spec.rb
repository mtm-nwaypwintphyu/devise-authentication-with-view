require 'rails_helper'

RSpec.describe Posts::PostService, type: :service do
  let(:user) { create(:user) }

  # create
  describe '#create' do
    context 'with valid params' do
      let(:valid_params) { { title: 'Test Title', content: 'Some content', user_id: user.id } }

      it 'creates a post and returns status :created' do
        service = described_class.new(valid_params)
        result = service.create

        expect(result[:post]).to be_persisted
        expect(result[:status]).to eq(:created)
        expect(result[:post].title).to eq('Test Title')
      end
    end

    context 'with invalid params' do
      let(:invalid_params) { { title: '', content: '', user_id: nil } }

      it 'does not create a post and returns status :unprocessable_entity' do
        service = described_class.new(invalid_params)
        result = service.create

        expect(result[:post]).not_to be_persisted
        expect(result[:status]).to eq(:unprocessable_entity)
      end
    end
  end

  # update
  describe '#update' do
    let(:post) { create(:post, user: user) }

    context 'with valid params' do
      let(:update_params) { { title: 'Updated Title', content: 'Updated content' } }

      it 'updates the post and returns status :updated' do
        service = described_class.new(update_params)
        result = service.update(post)

        expect(result[:post].title).to eq('Updated Title')
        expect(result[:status]).to eq(:updated)
      end
    end

    context 'with invalid params' do
      let(:invalid_update_params) { { title: '', content: '' } }

      it 'does not update the post and returns status :unprocessable_entity' do
        service = described_class.new(invalid_update_params)
        result = service.update(post)

        expect(result[:post].errors).to be_present
        expect(result[:status]).to eq(:unprocessable_entity)
      end
    end
  end

  # destroy
  describe '#destroy' do
    let!(:post) { create(:post, user: user) }

    context 'when post is successfully destroyed' do
      it 'destroys the post and returns true' do
        service = described_class.new({})
        result = service.destroy({ id: post.id })

        expect(result).to eq(true)
        expect(Post.exists?(post.id)).to be_falsey
      end
    end

    context 'when the post does not exist' do
      it 'raises an error and returns false or exception' do
        service = described_class.new({})
        expect {
          service.destroy({ id: -1 })
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
