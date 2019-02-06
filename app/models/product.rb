class Product < ApplicationRecord
  belongs_to :category

  has_one_attached :picture

  after_validation :if_picture_not_valid_remove_it

  validates :picture,
            file_content_type: { allow: ['image/jpeg', 'image/png'] },
            if: -> { picture.attachment.present? }

  validates :title, presence: true,
            length: { maximum: 250 }

  validates :price, presence: true,
            numericality: { greater_than_or_equal_to: 0 }

  def if_picture_not_valid_remove_it
    self.picture.purge if self.errors.present? && self.errors.details.key?(:picture)
  end
end
