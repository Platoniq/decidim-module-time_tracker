# frozen_string_literal: true

Decidim::Core::Engine.routes.draw do
  # if Rails.env.development?
  #   mount LetterOpenerWeb::Engine, at: "/letter_opener"
  # end

  # mount Decidim::Core::Engine => '/'
  # # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  authenticate(:user) do
    resources :voluntary_work, controller: "time_tracker/voluntary_work"
  end

end
