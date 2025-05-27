class BaseForm
  VirtusMixin = Virtus.model
  include VirtusMixin
  include ActiveModel::Model
  include ActiveModel::Validations

  attribute :id, Integer
end
