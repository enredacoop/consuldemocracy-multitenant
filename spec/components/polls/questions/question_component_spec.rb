require "rails_helper"

describe Polls::Questions::QuestionComponent do
  let(:poll) { create(:poll) }
  let(:question) { create(:poll_question, :yes_no, poll: poll) }
  let(:option_yes) { question.question_options.find_by(title: "Yes") }
  let(:option_no) { question.question_options.find_by(title: "No") }
  let(:user) { User.new }
  let(:web_vote) { Poll::WebVote.new(poll, user) }
  let(:form) { ConsulFormBuilder.new(:web_vote, web_vote, ApplicationController.new.view_context, {}) }

  it "renders more information links when any question option has additional information" do
    allow_any_instance_of(Poll::Question::Option).to receive(:with_read_more?).and_return(true)

    render_inline Polls::Questions::QuestionComponent.new(question, form: form)

    page.find("#poll_question_#{question.id}") do |poll_question|
      expect(poll_question).to have_content "Read more about"
      expect(poll_question).to have_link "Yes", href: "#option_#{option_yes.id}"
      expect(poll_question).to have_link "No", href: "#option_#{option_no.id}"
      expect(poll_question).to have_content "Yes, No"
    end
  end

  it "renders answers in given order" do
    render_inline Polls::Questions::QuestionComponent.new(question, form: form)

    expect("Yes").to appear_before("No")
  end

  context "Verified user" do
    let(:user) { create(:user, :level_two) }
    before { sign_in(user) }

    it "renders radio buttons for single-choice questions" do
      render_inline Polls::Questions::QuestionComponent.new(question, form: form)

      expect(page).to have_field "Yes", type: :radio
      expect(page).to have_field "No", type: :radio
      expect(page).to have_field type: :radio, checked: false, count: 2
    end

    it "renders checkboxes for multiple-choice questions" do
      question = create(:poll_question_multiple, :abc, poll: poll)

      render_inline Polls::Questions::QuestionComponent.new(question, form: form)

      expect(page).to have_field "Answer A", type: :checkbox
      expect(page).to have_field "Answer B", type: :checkbox
      expect(page).to have_field "Answer C", type: :checkbox
      expect(page).to have_field type: :checkbox, checked: false, count: 3
      expect(page).not_to have_field type: :checkbox, checked: true
    end

    it "selects the option when users have already voted" do
      create(:poll_answer, author: user, question: question, option: option_yes)

      render_inline Polls::Questions::QuestionComponent.new(question, form: form)

      expect(page).to have_field "Yes", type: :radio, checked: true
      expect(page).to have_field "No", type: :radio, checked: false
    end

    it "renders disabled answers when the user has already voted in a booth" do
      create(:poll_voter, :from_booth, poll: poll, user: user)

      render_inline Polls::Questions::QuestionComponent.new(question, form: form)

      page.find("fieldset[disabled]") do |fieldset|
        expect(fieldset).to have_field "Yes"
        expect(fieldset).to have_field "No"
      end
    end

    context "expired poll" do
      let(:poll) { create(:poll, :expired) }

      it "renders disabled answers when the poll has expired" do
        render_inline Polls::Questions::QuestionComponent.new(question, form: form)

        page.find("fieldset[disabled]") do |fieldset|
          expect(fieldset).to have_field "Yes"
          expect(fieldset).to have_field "No"
        end
      end
    end
  end

  context "geozone restricted poll" do
    let(:poll) { create(:poll, geozone_restricted: true) }
    let(:geozone) { create(:geozone) }
    before { poll.geozones << geozone }

    context "user from another geozone" do
      let(:user) { create(:user, :level_two) }
      before { sign_in(user) }

      it "renders disabled answers" do
        render_inline Polls::Questions::QuestionComponent.new(question, form: form)

        page.find("fieldset[disabled]") do |fieldset|
          expect(fieldset).to have_field "Yes"
          expect(fieldset).to have_field "No"
        end
      end
    end

    context "user from the same geozone" do
      let(:user) { create(:user, :level_two, geozone: geozone) }
      before { sign_in(user) }

      it "renders enabled answers" do
        render_inline Polls::Questions::QuestionComponent.new(question, form: form)

        expect(page).not_to have_css "fieldset[disabled]"
        expect(page).to have_field "Yes"
        expect(page).to have_field "No"
      end
    end
  end
end
