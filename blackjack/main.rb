require 'rubygems'
require 'sinatra'

set :sessions, true

BLACKJACK_NUM = 21
DEALER_MIN = 17

helpers do
  # method to calculate the player/dealer's hand. accounts for Aces!
  def calculate (cards)
    values = cards.map{|element| element[1]}
    total = 0
    values.each do |card|
      if card == 'ace'
        total += 11
        if total > BLACKJACK_NUM
          total -= 10
        end
      elsif card.to_i == 0
        total += 10
      elsif card.to_i > 0
        total += card.to_i
      end
    end
    total
  end

  # map card in array to the corresponding card image
  def display (card)
      image_name = "/images/cards/" + card[0] + "_" + card[1] + ".jpg"
      image_name
  end

  def playerwin
    session[:bet_total] = session[:bet_total] + session[:bet]*2
    session[:bet] = 0
    bankruptcy
  end

  def playerbust
    session[:bet] = 0
    bankruptcy
    @error = session[:name] + " busted with a total of #{calculate(session[:player_hand])}."
  end

  def playercomparelost
    session[:bet] = 0
    puts calculate(session[:dealer_hand])
    bankruptcy
    @error = session[:name] + " had #{calculate(session[:player_hand])} and Dealer had #{calculate(session[:dealer_hand])}. #{session[:name]} lost."
  end

  def playercomparewin
    session[:bet_total] = session[:bet_total] + session[:bet]*2
    session[:bet] = 0
    bankruptcy
    @success = session[:name] + " had #{calculate(session[:player_hand])} and Dealer had #{calculate(session[:dealer_hand])}. #{session[:name]} won!"
  end

  def dealergotblackjack
    session[:bet] = 0
    puts calculate(session[:dealer_hand])
    bankruptcy
    @error = "Dealer got Blackjack! #{session[:name]} lost."
  end

  def dealerbust
    session[:bet_total] = session[:bet_total] + session[:bet]*2
    session[:bet] = 0
    bankruptcy
    @success = "Dealer busted with #{calculate(session[:dealer_hand])}. #{session[:name]} won!"
  end

  def playertie
    session[:bet_total] = session[:bet_total] + session[:bet]
    session[:bet] = 0
    bankruptcy
    @success = "It was a tie!"
  end

  def ddbust
    @error = "#{session[:name]}'s Double Down busted with a total of #{calculate(session[:player_hand])}. #{session[:name]} lost $#{session[:bet]} :("
    session[:bet] = 0
    puts calculate(session[:dealer_hand])
    bankruptcy
  end


  def playerblackjack
    session[:betextra] = session[:bet]*1.50
    session[:bet_total] = session[:bet_total] + session[:bet] + session[:betextra]
    session[:bet] = 0
    session[:betextra] = 0
    bankruptcy
    @success = "Blackjack! Woo hoo! You won some extra money."
  end

  def bankruptcy
    if session[:bet_total] == 0
      @gameover = false
      @ranout = true
    end
  end

end

before do
  @show_hit_or_stay = true
end

get '/' do
  # if there is a name stored in cookie, skip ahead to start game
  if session[:name]
    redirect "/game"
  else
    redirect "/new"
  end
end

get '/new' do
  @new_game = true
  session[:bet_total] = 500
  session[:bet] = 0
  session[:name] = "Player"
  erb :new
end

post '/new' do
  @new_game = true
  # make sure field is not empty still
  if params[:name].empty?
    @error = "Name is required!"
    halt erb :new
  end
  # if okay, then set name and then redirect to place a bet
  session[:name] = params[:name].capitalize
  session[:bet_total] = 500
  session[:bet] = 0
  redirect '/bet'
end

post '/game' do
  params[:bet] = params[:bet].to_i
  if params[:bet] > 0 && params[:bet] <= session[:bet_total]
    session[:bet] = params[:bet]
    redirect "/game"
  else
    @error = "Please enter a valid bid!"
    @gameover
    @show_hit_or_stay = false
    erb :game
  end
end

get '/game' do
  @ddavailable = true
  if session[:bet_total] < 0
    @error = "You don't have enough money!"
    @ranout = true
    @show_hit_or_stay = false
  end

  if session[:bet] == 0
    redirect '/new'
  end
  session[:bet_total] = session[:bet_total] - session[:bet]
  # creates deck of cards and shuffles them
  suit = ['hearts', 'diamonds', 'clubs', 'spades']
  value = ['ace', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'jack', 'queen', 'king']
  session[:deck] = suit.product(value).shuffle

  # deal cards out to begin game
  session[:dealer_hand] = []
  session[:player_hand] = []
  session[:player_hand].push(session[:deck].pop)
  session[:dealer_hand].push(session[:deck].pop)
  session[:player_hand].push(session[:deck].pop)
  session[:dealer_hand].push(session[:deck].pop)
  # check for automatic player blackjack win
  if calculate(session[:player_hand]) == BLACKJACK_NUM
      @show_hit_or_stay = false
      @gameover = true
      playerblackjack
  end
  erb :game
end

post '/doubledown' do
  # change bet ammount to 2x
  session[:bet_total] = session[:bet_total] - session[:bet]
  session[:bet] = session[:bet]*2
  session[:player_hand].push(session[:deck].pop)
  player_total = calculate(session[:player_hand])

  if player_total > BLACKJACK_NUM
    playert = calculate(session[:player_hand])
    @show_hit_or_stay = false
    @gameover = true
    ddbust
  elsif player_total == BLACKJACK_NUM
    @success = "Wow! #{session[:name]} got Blackjack on a Double Down and won #{session[:bet]}!!"
    @show_hit_or_stay = false
    @gameover = true
    playerwin
  # if < 21 after double down, continue playing with dealer's turn
  else
    player_total =calculate(session[:player_hand])
    @success = "Double Down! #{session[:name]}'s total is now #{player_total} and it is the dealer's turn."
    @show_hit_or_stay = false
    @dealer_turn = true
    if calculate(session[:dealer_hand]) >= DEALER_MIN
      @compare = true
    end
  end
  erb:game
end

post '/hit' do
  session[:player_hand].push(session[:deck].pop)
  player_total = calculate(session[:player_hand])
  if player_total > BLACKJACK_NUM
    @show_hit_or_stay = false
    @gameover = true
    playerbust
  elsif player_total == BLACKJACK_NUM
    @show_hit_or_stay = false
    @gameover = true
    playerblackjack
  end
  erb :game, layout: false
end

post '/stay' do
  @success = "You decided to stay! It's the Dealer's turn."
  @show_hit_or_stay = false
  @dealer_turn = true
  # show compare button if dealer is already at 17
  if calculate(session[:dealer_hand]) >= DEALER_MIN
    @compare = true
  end
  erb :game, layout: false
end

post '/dealer' do
  @dealer_turn = true
  erb :game, layout: false
end

post '/dealer-turn' do
  @show_hit_or_stay = false
  dtotal = calculate(session[:dealer_hand])
  # check first in dealer has blackjack. if so, end game
  if dtotal == BLACKJACK_NUM
    @gameover = true
    dealergotblackjack
  # if Dealear has over 17, then turn is over.
  elsif dtotal >= DEALER_MIN
    @error = "Dealer's total is #{dtotal} and stays."
    @compare = true
  # if dealer does not have blackjack and has less than 17, then hit
  elsif dtotal < DEALER_MIN
    session[:dealer_hand].push(session[:deck].pop)
    dtotal = calculate(session[:dealer_hand])
    # check if with new card, have blackjack
    if dtotal == BLACKJACK_NUM
      @gameover = true
      dealergotblackjack
    # check if with new card, have bust
    elsif dtotal > BLACKJACK_NUM
      @success = "Dealer busted. #{session[:name]} wins!"
      @gameover = true
      dealerbust
    # if dealer has 17 or more, but hasn't busted, then compare hand totals
    elsif dtotal >= DEALER_MIN
      @error = "Dealer's total is #{dtotal} and stays. Let's see who won..."
      @compare = true
    else
      @dealer_turn = true
    end
  end
  erb :game, layout: false
end

post '/compare' do
  @show_hit_or_stay = false
  dealer_final = calculate(session[:dealer_hand])
  player_final = calculate(session[:player_hand])

  if dealer_final > player_final
    @gameover = true
    playercomparelost
  elsif dealer_final < player_final
    @gameover = true
    playercomparewin
  else
    @gameover = true
    playertie
  end
  erb :game, layout: false
end

post '/game' do
  if params[:bet] > 0 && params[:bet] <=500
    session[:bet] = params[:bet]
    redirect "/game"
  else
    @error = "Please enter a valid bid!"
    erb :bet
  end
end

post '/bet' do
  @new_game = true
  params[:bet] = params[:bet].to_i
  if params[:bet] > 0 && params[:bet] <=500
    session[:bet] = params[:bet]
    redirect "/game"
  else
    @error = "Please enter a valid bid!"
    erb :bet
  end
end

get '/bet' do
  @new_game = true
  erb :bet
end

post '/replay' do
  params[:bet] = params[:bet].to_i
  puts params[:bet]
  if params[:bet] > 0 && params[:bet] <= session[:bet_total]
    session[:bet] = params[:bet]
    redirect "/game"
  else
    @error = "Please enter a valid bid!"
    @show_hit_or_stay = false
    @gameover = true
    erb :game
  end
end

get '/cashout' do
  @new_game = true
  erb :cashout
end

get '/end' do
  @new_game = true
  erb :cashout
end
