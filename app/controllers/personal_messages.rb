Chessboard::App.controllers :personal_messages do

  before do
    env["warden"].authenticate!
  end

  get :index, :map => "/pms" do
    @pms = env["warden"].user.allowed_pms.joins(:posts).group("personal_messages.id").order("personal_posts.updated_at DESC")
    render "index"
  end

  get :new, :map => "/pms/new" do
    @pm = PersonalMessage.new
    @pm.posts.build(:markup_language => env["warden"].user.settings.preferred_markup_language)

    render "new"
  end

  post :create, :map => "/pms" do
    @pm = PersonalMessage.new

    @pm.title = params["personal_message"]["title"]
    @pm.author = env["warden"].user

    initial_post = PersonalPost.new(params["personal_message"]["posts_attributes"]["0"])
    initial_post.author = env["warden"].user
    @pm.posts << initial_post

    params["personal_message"]["allowed_users"].split(/,\s?/).each do |nickname|
      if user = User.where(:nickname => nickname).first
        @pm.allowed_users << user
      else
        @pm.errors.add(:allowed_users, I18n.t("errors.pm.unknown_recipient", :nickname => nickname))
        return render("new")
      end
    end

    if @pm.save
      flash["notice"] = I18n.t("pms.created")
      redirect url(:personal_messages, :show, @pm.id)
    else
      render "new"
    end
  end

  get :show, :map => "/pms/:id" do
    @pm = PersonalMessage.find(params["id"])
    halt 403 unless @pm.allowed_users.include?(env["warden"].user)

    @pm.views += 1
    @pm.users_who_read_this << env["warden"].user unless env["warden"].user.read_pm?(@pm)
    @pm.save

    render "show"
  end

  get :edit, :map => "/pms/:id/edit" do
  end

  patch :update, :map => "/pms/:id" do
  end

  delete :destroy, :map => "/pms/:id" do
    @pm = PersonalMessage.find(params["id"])
    @pm.destroy!

    flash[:notice] = I18n.t("pms.deleted")
    redirect url(:pms, :index)
  end

end
