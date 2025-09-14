class FeedbacksController < ApplicationController
  def new
    @feedback = Feedback.new

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def create
    @feedback = Feedback.new(feedback_params)

    if @feedback.save
      # Could also send an email notification here
      FeedbackMailer.new_feedback(@feedback).deliver_later if defined?(FeedbackMailer)

      respond_to do |format|
        format.html {
          redirect_to root_path,
          notice: "Thank you for your feedback! We'll review it soon."
        }
        format.turbo_stream {
          render turbo_stream: [
            turbo_stream.replace("feedback_form",
              partial: "feedbacks/success",
              locals: { feedback: @feedback }
            ),
            turbo_stream.prepend("notifications",
              partial: "shared/notification",
              locals: {
                message: "Thank you for your feedback!",
                type: "success"
              }
            )
          ]
        }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace(
            "feedback_form",
            partial: "feedbacks/form",
            locals: { feedback: @feedback }
          )
        }
      end
    end
  end

  private

  def feedback_params
    params.require(:feedback).permit(:feedback_type, :title, :description, :email, :feed_url)
  end
end
