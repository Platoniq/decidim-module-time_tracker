# frozen_string_literal: true

module Decidim
  module TimeTracker
    # Uploader for the illustrative image of an Activity.
    class ActivityImageUploader < Decidim::ImageUploader
      set_variants do
        {
          thumb: { resize_to_fill: [80, 80] },
          card: { resize_to_limit: [1280, 400] }
        }
      end
    end
  end
end
