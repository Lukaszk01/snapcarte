class RestaurantsController < ApplicationController


  def show

    @restaurant = Restaurant.find(params[:id])
    @markers = [{ lat: @restaurant.latitude,
                lng: @restaurant.longitude
              }]
    @cart = Cart.find_by_user_and_restaurant(current_user, @restaurant) || Cart.create(user: current_user, restaurant: @restaurant)
    if params[:request] && @cart
      @quote = QuoteGetter.call(@cart)
    end
    authorize @restaurant
  end

  def new
    if params[:scraping] != nil
      url = params[:scraping][:url]
       @restaurant = scrape_restaurant(url)
    else
      @restaurant = Restaurant.new
    end
    @restaurant.menus.build
    authorize @restaurant
  end

  def create
    @restaurant = Restaurant.new(restaurant_params)
    @restaurant.user = current_user
    authorize @restaurant
    if @restaurant.save
      redirect_to edit_menus_restaurant_path(@restaurant)
    else
      render :new
    end
  end

  def update
    @restaurant = Restaurant.find(params[:id])
    @restaurant.open = !@restaurant.open
    authorize @restaurant
    @restaurant.save
    redirect_to restaurant_path(@restaurant)
  end

  def edit_menus
    @restaurant = Restaurant.find(params[:id])
    authorize @restaurant
  end

  def update_menus
    @restaurant = Restaurant.find(params[:id])
    authorize @restaurant
    if @restaurant.update(restaurant_menu_params)
      redirect_to edit_menus_restaurant_path(@restaurant)
    else
      render :edit_menus
    end
  end

  private
    require 'open-uri'
  def scrape_restaurant(url)
    html_file = open(url).read
    html_doc = Nokogiri::HTML(html_file)
    Restaurant.new(
      address: html_doc.search('.restaurants-detail-top-info-TopInfo__infoCellLink--2ZRPG')[1].text.strip,
      phone_number: html_doc.search('.restaurants-detail-top-info-TopInfo__infoCellLink--2ZRPG')[2].text.strip,
      cuisine: html_doc.search('.restaurants-detail-overview-cards-DetailsSectionOverviewCard__tagText--1OH6h')[0].text.strip,
      name: html_doc.search('.restaurants-detail-top-info-TopInfo__restaurantName--1IKBe').text.strip
      )
  end

  def restaurant_params
    params.require(:restaurant).permit(:description, :photo, :name, :address, :coords, :phone_number, :cuisine, :menu_photo)
  end

  def restaurant_menu_params
    params.require(:restaurant).permit(menus_attributes: [:id, :name, dishes_attributes: [:id, :name,:price]])
    # params.require(:menu).permit(dishes_attributes: [:id, :name, :price])
  end

end
