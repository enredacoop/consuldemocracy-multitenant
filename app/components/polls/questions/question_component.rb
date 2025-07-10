class Polls::Questions::QuestionComponent < ApplicationComponent
  attr_reader :question, :form
  use_helpers :cannot?, :current_user

  def initialize(question, form:)
    @question = question
    @form = form
  end

  private

    def fieldset_attributes
      tag.attributes(
        id: dom_id(question),
        disabled: ("disabled" if disabled?),
        class: fieldset_class,
        data: { max_votes: question.max_votes }
      )
    end

    def fieldset_class
      if multiple_choice?
        "multiple-choice"
      else
        "single-choice"
      end
    end

    def options_read_more_links
      safe_join(question.options_with_read_more.map do |option|
        link_to option.title, "#option_#{option.id}"
      end, ", ")
    end

    def multiple_choice?
      question.max_votes > 1
    end

    def disabled?
      cannot?(:answer, question.poll) || question.poll.voted_in_booth?(current_user)
    end

    def multiple_choice_help_text
      tag.span(
        t("poll_questions.description.multiple", maximum: question.max_votes),
        class: "help-text"
      )
    end

    def multiple_choice_field(option)
      choice_field(option) do
        check_box_tag "web_vote[#{question.id}][option_id][]",
                      option.id,
                      checked?(option),
                      id: "web_vote_option_#{option.id}"
      end
    end

    def single_choice_field(option)
      choice_field(option) do
        radio_button_tag "web_vote[#{question.id}][option_id]",
                         option.id,
                         checked?(option),
                         id: "web_vote_option_#{option.id}"
      end
    end

    def choice_field(option, &block)
      label_tag("web_vote_option_#{option.id}") do
        block.call + option.title
      end
    end

    def checked?(option)
      form.object.answers[question.id].find { |answer| answer.option_id == option.id }
    end
end
