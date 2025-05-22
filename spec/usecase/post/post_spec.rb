require 'rails_helper'

RSpec.describe Posts::PostUsecase do
  # create post
  describe '#create' do
    let(:valid_params) { { title: 'Valid Title', content: 'Valid content' } }
    let(:invalid_params) { { title: '', content: '' } }

    context 'when the form is valid' do   
      it 'calls the post service create method and returns the response' do   

        form = instance_double('Posts::PostForm', valid?: true, attributes: valid_params)
        service = instance_double('Posts::PostService', create: { post: 'created_post', status: :created })

        allow(Posts::PostForm).to receive(:new).with(valid_params).and_return(form)
        allow(Posts::PostService).to receive(:new).with(valid_params).and_return(service)

        usecase = described_class.new(valid_params)
        result = usecase.create

        expect(result).to eq({ post: 'created_post', status: :created })
        expect(Posts::PostForm).to have_received(:new).with(valid_params)
        expect(service).to have_received(:create)
      end
    end

    context 'when the form is invalid' do
      it 'returns errors with status unprocessable_entity' do
        usecase = described_class.new(invalid_params)
        result = usecase.create

        expect(result[:status]).to eq(:unprocessable_entity)
        expect(result[:errors]).not_to be_empty

        expect(result[:errors][:title].flatten).to include("Title cannot be empty.")
        expect(result[:errors][:content].flatten).to include("Content cannot be empty.")
      end
    end

    context 'when an exception is raised' do
      it 'returns the error message with status unprocessable_entity' do
        form = instance_double('Posts::PostForm', valid?: true, attributes: valid_params)
        allow(Posts::PostForm).to receive(:new).and_return(form)

        service = instance_double('Posts::PostService')
        allow(Posts::PostService).to receive(:new).and_return(service)
        allow(service).to receive(:create).and_raise(StandardError.new('Something went wrong'))

        usecase = described_class.new(valid_params)
        result = usecase.create

        expect(result[:status]).to eq(:unprocessable_entity)
        expect(result[:errors]).to eq('Something went wrong')
      end
    end
  end

  # update
  describe '#update' do
    let(:user) { create(:user) }
    let(:post) { create(:post, user: user) }
    let(:valid_params) { { title: 'Valid title', content: 'Valid content' } }
    let(:invalid_params) { { title: '', content: '' } }

    context 'when the form is valid' do
      it 'calls the post service and returns updated post and status' do
        form = instance_double('Posts::PostForm', valid?: true, attributes: valid_params)
        allow(Posts::PostForm).to receive(:new).with(valid_params).and_return(form)

        updated_post = instance_double('Post', title: 'Valid title', content: 'Valid content')

        service = instance_double('Posts::PostService')
        allow(Posts::PostService).to receive(:new).with(valid_params).and_return(service)
        allow(service).to receive(:update).with(post).and_return({ post: updated_post, status: :updated })

        usecase = described_class.new(valid_params)
        result = usecase.update(post)

        expect(result[:status]).to eq(:updated)
        expect(result[:post].title).to eq('Valid title')
        expect(result[:post].content).to eq('Valid content')
      end
    end
    context 'when the form is invalid' do
      it 'returns errors with status unprocessable_entity' do
        usecase = described_class.new(invalid_params)
        result = usecase.update(invalid_params)

        expect(result[:status]).to eq(:unprocessable_entity)
        expect(result[:errors]).not_to be_empty

        expect(result[:errors][:title].flatten).to include("Title cannot be empty.")
        expect(result[:errors][:content].flatten).to include("Content cannot be empty.")

      end
    end
    context 'when an exception is raised' do
      it 'returns the error message with status unprocessable_entity' do
        form = instance_double('Posts::PostForm', valid?: true, attributes: valid_params)
        allow(Posts::PostForm).to receive(:new).and_return(form)

        service = instance_double('Posts::PostService')
        allow(Posts::PostService).to receive(:new).and_return(service)
        allow(service).to receive(:update).and_raise(StandardError.new('Something went wrong'))

        usecase = described_class.new(valid_params)
        result = usecase.update(valid_params)

        expect(result[:status]).to eq(:unprocessable_entity)
        expect(result[:errors]).to eq('Something went wrong')
      end
    end
  end

  # destroy
  describe '#destroy' do
    let(:user) { create(:user) }
    let(:post) { create(:post, user: user) }
    let(:params) { {} }

    subject { described_class.new(params) }

    context 'when post is successfully destroyed' do
      it 'returns true' do
        service = instance_double('Posts::PostService')
        allow(Posts::PostService).to receive(:new).with(params).and_return(service)
        allow(service).to receive(:destroy).with(post).and_return(true)

        result = subject.destroy(post)
        expect(result).to eq(true)
      end
    end

    context 'when post destroy fails' do
      it 'returns false' do
        service = instance_double('Posts::PostService')
        allow(Posts::PostService).to receive(:new).with(params).and_return(service)
        allow(service).to receive(:destroy).with(post).and_return(false)

        result = subject.destroy(post)
        expect(result).to eq(false)
      end
    end

    context 'when an exception is raised' do
      it 'returns an error hash with status' do
        service = instance_double('Posts::PostService')
        allow(Posts::PostService).to receive(:new).with(params).and_return(service)
        allow(service).to receive(:destroy).with(post).and_raise(StandardError.new("Something went wrong"))

        result = subject.destroy(post)
        expect(result).to eq({ post: nil, errors: "Something went wrong", status: :unprocessable_entity })
      end
    end
  end
end
