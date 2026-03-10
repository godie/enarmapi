class V2KnowledgeBaseController < ApplicationController
  before_action :authenticate_user!

  def index
    topics = Topic.includes(:articles)

    if params[:topic].present?
      topics = topics.where("title LIKE ?", "%#{params[:topic]}%")
    end

    if params[:search].present?
      search = "%#{params[:search]}%"
      topics = topics.joins(:articles).where("articles.title LIKE :search OR articles.content LIKE :search", search: search).distinct
    end

    render json: {
      topics: topics.map { |t|
        {
          id: "t#{t.id}",
          title: t.title,
          articles: t.articles.map { |a| { id: "a#{a.id}", title: a.title } }
        }
      }
    }
  end
end
