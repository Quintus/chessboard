Chessboard::App.controllers :bans do

  get :index, :map => "/moderation/bans" do
    @bans = Ban.order(:created_at => :desc)
    render "moderation/bans/index"
  end

  get :new, :map => "/moderation/bans/new" do
    @ban = Ban.new
    render "moderation/bans/new"
  end

  post :create, :map => "/moderation/bans" do
    @ban = Ban.new(params["ban"])

    if @ban.save
      flash[:notice] = I18n.t("bans.created")
      create_modlog_entry(@ban, :create)
      redirect url(:bans, :index)
    else
      render "moderation/bans/new"
    end
  end

  get :edit, :map => "/moderation/bans/:id/edit" do
    @ban = Ban.find(params["id"])
    render "moderation/bans/edit"
  end

  patch :update, :map => "/moderation/bans/:id" do
    @ban = Ban.find(params["id"])

    if @ban.update_attributes(params["ban"])
      flash[:notice] = I18n.t("bans.updated")
      create_modlog_entry(@ban, :update)
      redirect url(:bans, :index)
    else
      render "moderation/bans/edit"
    end
  end

  delete :destroy, :map => "/moderation/bans/:id" do
    @ban = Ban.find(params["id"])
    @ban.destroy

    create_modlog_entry(@ban, :destroy)

    flash[:notice] = I18n.t("bans.deleted")
    redirect url(:bans, :index)
  end

end

def create_modlog_entry(ban, modification)
  ary = []
  ary << "nick=#{ban.nick_pattern}"   unless ban.nick_pattern.blank?
  ary << "email=#{ban.email_pattern}" unless ban.email_pattern.blank?
  ary << "ip=#{ban.ip_range}"         unless ban.ip_range.blank?

  if modification == :create
    action = "Cast a ban on #{ary.join('/')} that will"
    action += ban.expiration_date? ? "expire on #{ban.expiration_date}" : "never expire"
    action += ". #{ban.reason}"
  elsif modification == :update
    action = "Modified the ban on #{ary.join('/')} that will"
    action += ban.expiration_date? ? "expire on #{ban.expiration_date}" : "never expire"
    action += ". #{ban.reason}"
  elsif modification == :destroy
    action = "Released the ban on #{ary.join('/')}."
  else
    logger.error "Invalid modlog entry request in bans.rb: #{modification} #{ban.inspect}"
    return
  end

  Moderation.create(:moderator => env["warden"].user, :action => action)
end
