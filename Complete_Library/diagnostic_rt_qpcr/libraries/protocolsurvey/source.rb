# frozen_string_literal: true

# Includes methods for giving a survey to the Tech and get ting answers.

module ProtocolSurvey

  def protocol_survey(operations)
    question1 = 'Are you aware of any mistakes or errors that may have occurred '\
                'while executing this Job?  If so briefly explain.'
    survey = show do
      title 'Protocol Survey'
      separator
      note question1
      get('text',
          var: question1,
          label: "Put 'NA' if not applicable",
          default: '')
    end
    answers = [{question: question1, response: survey.get_response(question1)}]
    associate_answers(operations: operations, answers: answers)
  end

  def workflow_survey(operations)
    question1 = 'Were all the instructions for this job clear? '\
                'If not, please specify.'
    question2 = 'Were any parts of the workflow not helpful? '\
                  'If so, please specify which steps.'
    survey = show do
      title 'Protocol Survey'
      separator
      note question1
      get('text',
          var: question1,
          label: "Put 'NA' if not applicable",
          default: '')
      separator
      note question2
      get('text',
          var: question2,
          label: "Put 'NA' if not applicable",
          default: '')
    end
    answers  =[
      { question: question1, response: survey.get_response(question1) },
      { question: question2, response: survey.get_response(question2) }
    ]
    associate_answers(operations: operations, answers: answers)
  end

  def associate_answers(operations:, answers:)
    show do
      title 'Recorded Responses'
      note 'Your responses were:'
      answers.each do |answers|
        note "Question: #{answers[:question]}"
        note "Answer: #{answers[:response]}"
      end
    end
    operations.each do |op|
      op.associate('survey_answers', answers)
    end
  end

end
