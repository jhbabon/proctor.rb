# Public: Model the ability of a User to use other objects.
class Ability
  def initialize(user)
    @user = user
  end

  def can_use?(thing)
    return true if @user.admin?
    return false if @user.guest?

    case thing.class.name
    when "User"
      @user.id == thing.id
    when "Pubkey"
      @user.pubkeys.where(:id => thing.id).exists?
    else
      false
    end
  end
end
