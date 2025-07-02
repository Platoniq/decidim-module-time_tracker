# frozen_string_literal: true

require "spec_helper"

# We make sure that the checksum of the file overridden is the same
# as the expected. If this test fails, it means that the overridden
# file should be updated to match any change/bug fix introduced in the core
checksums = [
  {
    package: "decidim-forms",
    files: {
      # Customized files containing shared examples on /lib/decidim/time_tracker/test/ to allow selecting the desired questionnaire on tests
      "/lib/decidim/forms/test/shared_examples/manage_questionnaires.rb" => "815411006f59c0ca166e56461efc924a",
      "/lib/decidim/forms/test/shared_examples/manage_questionnaire_answers.rb" => "5e7e43e6bc8221b2571cd2cdd2024f5f",
      "/lib/decidim/forms/test/shared_examples/manage_questionnaires/update_questions.rb" => "efb8350809a8372c2a2017040df12531"
    }
  }
]

describe "Overridden files", type: :view do
  checksums.each do |item|
    spec = Gem::Specification.find_by_name(item[:package])

    item[:files].each do |file, signature|
      next unless spec

      it "#{spec.gem_dir}#{file} matches checksum" do
        expect(md5("#{spec.gem_dir}#{file}")).to eq(signature)
      end
    end
  end

  private

  def md5(file)
    Digest::MD5.hexdigest(File.read(file))
  end
end
