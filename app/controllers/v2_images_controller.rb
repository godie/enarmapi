class V2ImagesController < ApplicationController
  before_action :authenticate_user!

  def bank
    # El banco de imágenes se basa en casos clínicos que tienen imágenes adjuntas
    cases = ClinicalCase.with_attached_image.published

    if params[:category].present?
      cases = cases.joins(:category).where(categories: { name: params[:category] })
    end

    if params[:search].present?
      search = "%#{params[:search]}%"
      cases = cases.where("clinical_cases.name LIKE :search OR clinical_cases.tags LIKE :search", search: search)
    end

    cases = cases.paginate(page: params[:page] || 1, per_page: 20)

    render json: {
      images: cases.map { |c|
        {
          id: "img#{c.id}",
          url: (rails_blob_url(c.image, only_path: false) rescue nil),
          title: c.name,
          category: c.category.name,
          tags: c.tag_list
        }
      },
      pagination: {
        current: cases.current_page,
        total: cases.total_pages
      }
    }
  end
end
