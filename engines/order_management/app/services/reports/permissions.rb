module Reports
  class Permissions
    attr_accessor :user

    def initialize(user)
      @user = user
    end
  end
end
