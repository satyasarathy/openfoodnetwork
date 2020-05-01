# Validates an integer array
#
# This uses Integer() behind the scenes.
#
# === Example
#
#   class Post
#     include ActiveModel::Validations
#
#     attr_accessor :related_post_ids
#     validates :related_post_ids, integer_array: true
#   end
#
#   post = Post.new
#
#   post.related_post_ids = nil
#   post.valid?                     # => true
#
#   post.related_post_ids = []
#   post.valid?                     # => true
#
#   post.related_post_ids = 1
#   post.valid?                     # => false
#   post.errors[:related_post_ids]  # => ["must be an array"]
#
#   post.related_post_ids = [1, 2, 3]
#   post.valid?                     # => true
#
#   post.related_post_ids = ["1", "2", "3"]
#   post.valid?                     # => true
#
#   post.related_post_ids = [1, "2", "Not Integer", 3]
#   post.valid?                     # => false
#   post.errors[:related_post_ids]  # => ["must contain only valid integers"]
class IntegerArrayValidator < ActiveModel::EachValidator
  NOT_ARRAY_ERROR = I18n.t("validators.integer_array_validator.not_array_error")
  INVALID_ELEMENT_ERROR = I18n.t("validators.integer_array_validator.invalid_element_error")

  def validate_each(record, attribute, value)
    return if value.nil?

    validate_attribute_is_array(record, attribute, value)
    validate_attribute_elements_are_integer(record, attribute, value)
  end

  protected

  def validate_attribute_is_array(record, attribute, value)
    return if value.is_a?(Array)

    record.errors.add(attribute, NOT_ARRAY_ERROR)
  end

  def validate_attribute_elements_are_integer(record, attribute, array)
    return unless array.is_a?(Array)

    array.each do |element|
      Integer(element)
    end
  rescue ArgumentError
    record.errors.add(attribute, INVALID_ELEMENT_ERROR)
  end
end
