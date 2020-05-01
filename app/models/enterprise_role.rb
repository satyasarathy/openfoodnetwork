class EnterpriseRole < ActiveRecord::Base
  belongs_to :user, class_name: Spree.user_class
  belongs_to :enterprise

  validates :user_id, :enterprise_id, presence: true
  validates :enterprise_id, uniqueness: { scope: :user_id, message: I18n.t(:enterprise_role_uniqueness_error) }

  scope :by_user_email, -> { joins(:user).order('spree_users.email ASC') }
end
