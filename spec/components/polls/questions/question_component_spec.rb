require "rails_helper"

describe Polls::Questions::QuestionComponent do
  let(:poll) { create(:poll) }
  let(:question) { create(:poll_question, :yes_no, poll: poll) }
  let(:option_yes) { question.question_options.find_by(title: "Yes") }
  let(:option_no) { question.question_options.find_by(title: "No") }

  it "renders more information links when any question option has additional information" do
    allow_any_instance_of(Poll::Question::Option).to receive(:with_read_more?).and_return(true)

    render_inline Polls::Questions::QuestionComponent.new(question)

    page.find("#poll_question_#{question.id}") do |poll_question|
      expect(poll_question).to have_content "Read more about"
      expect(poll_question).to have_link "Yes", href: "#option_#{option_yes.id}"
      expect(poll_question).to have_link "No", href: "#option_#{option_no.id}"
      expect(poll_question).to have_content "Yes, No"
    end
  end

  it "renders answers in given order" do
    render_inline Polls::Questions::QuestionComponent.new(question)

    expect("Yes").to appear_before("No")
  end

  it "renders radio buttons for single-choice questions" do
    sign_in(create(:user, :verified))

    render_inline Polls::Questions::QuestionComponent.new(question)

    expect(page).to have_field "Yes", type: :radio
    expect(page).to have_field "No", type: :radio
    expect(page).to have_field type: :radio, checked: false, count: 2
  end

  it "renders checkboxes for multiple-choice questions" do
    sign_in(create(:user, :verified))

    render_inline Polls::Questions::QuestionComponent.new(create(:poll_question_multiple, :abc))

    expect(page).to have_field "Answer A", type: :checkbox
    expect(page).to have_field "Answer B", type: :checkbox
    expect(page).to have_field "Answer C", type: :checkbox
    expect(page).to have_field type: :checkbox, checked: false, count: 3
    expect(page).not_to have_field type: :checkbox, checked: true
  end

  it "selects the option when users have already voted" do
    user = create(:user, :verified)
    create(:poll_answer, author: user, question: question, option: option_yes)
    sign_in(user)

    render_inline Polls::Questions::QuestionComponent.new(question)

    expect(page).to have_field "Yes", type: :radio, checked: true
    expect(page).to have_field "No", type: :radio, checked: false
  end

  it "renders disabled answers when the user has already voted in a booth" do
    user = create(:user, :level_two)
    create(:poll_voter, :from_booth, poll: poll, user: user)
    sign_in(user)

    render_inline Polls::Questions::QuestionComponent.new(question)

    page.find("fieldset[disabled]") do |fieldset|
      expect(fieldset).to have_field "Yes"
      expect(fieldset).to have_field "No"
    end
  end

  it "renders disabled answers when the poll has expired" do
    question = create(:poll_question, :yes_no, poll: create(:poll, :expired))
    sign_in(create(:user, :level_two))

    render_inline Polls::Questions::QuestionComponent.new(question)

    page.find("fieldset[disabled]") do |fieldset|
      expect(fieldset).to have_field "Yes"
      expect(fieldset).to have_field "No"
    end
  end

  context "geozone restricted poll" do
    let(:poll) { create(:poll, geozone_restricted: true) }
    let(:geozone) { create(:geozone) }

    it "renders disabled answers for users from another geozone" do
      poll.geozones << geozone
      sign_in(create(:user, :level_two))

      render_inline Polls::Questions::QuestionComponent.new(question)

      page.find("fieldset[disabled]") do |fieldset|
        expect(fieldset).to have_field "Yes"
        expect(fieldset).to have_field "No"
      end
    end

    it "renders enabled answers for same-geozone users" do
      poll.geozones << geozone
      sign_in(create(:user, :level_two, geozone: geozone))

      render_inline Polls::Questions::QuestionComponent.new(question)

      expect(page).not_to have_css "fieldset[disabled]"
      expect(page).to have_field "Yes"
      expect(page).to have_field "No"
    end
  end
end
