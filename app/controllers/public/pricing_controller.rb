module Public
  class PricingController < BaseController
    # 가격 정책은 운영 안정화 후 공개됩니다.
    # 일반 모집은 진행하지 않으며, 매장별 진단 후 도입 여부를 협의합니다.
    def show
      # 의도적으로 비워둠: @plans / @monthly_krw / @deposit_krw 노출 없음.
    end
  end
end