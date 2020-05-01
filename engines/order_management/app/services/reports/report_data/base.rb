module Reports
  module ReportData
    class Base
      def initialize(attributes = {})
        attributes.each do |key, value|
          public_send("#{key}=", value)
        end
      end
    end
  end
end
