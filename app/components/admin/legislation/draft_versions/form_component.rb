class Admin::Legislation::DraftVersions::FormComponent < ApplicationComponent
  include TranslatableFormHelper
  include GlobalizeHelper
  attr_reader :draft_version, :url
  use_helpers :admin_submit_action

  def initialize(draft_version, url:)
    @draft_version = draft_version
    @url = url
  end

  private

    def process
      draft_version.process
    end

    def form_attributes
      {
        url: url,
        html: {
          data: { markdown_changes_message: markdown_changes_message }
        }
      }
    end

    def markdown_changes_message
      I18n.t("admin.legislation.draft_versions.edit.markdown_changes_message")
    end

    def submit_button_text
      t("admin.legislation.draft_versions.#{admin_submit_action(draft_version)}.submit_button")
    end
end
