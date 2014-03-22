$(document).ready(function() {
  player_hits();
  player_stays();
  dealer_continue();
  compare();
});

function player_hits(){
  $(document).on('click','#hitform input', function() {
    // alert ("HI");
    $.ajax({
      type:'POST',
      url: '/hit',
    }).done(function(msg){
      $('#game').replaceWith(msg);
    });
    return false;
  });
}

function player_stays(){
  $(document).on('click','#stayform input', function() {
    // alert ("HI");
    $.ajax({
      type:'POST',
      url: '/stay',
    }).done(function(msg){
      $('#game').replaceWith(msg);
    });
    return false;
  });
}

function compare(){
  $(document).on('click','#compare input', function() {
    // alert ("HI");
    $.ajax({
      type:'POST',
      url: '/compare',
    }).done(function(msg){
      $('#game').replaceWith(msg);
    });
    return false;
  });
}

function dealer_continue(){
  $(document).on('click','#cont input', function() {
    // alert ("HI");
    $.ajax({
      type:'POST',
      url: '/dealer-turn',
    }).done(function(msg){
      $('#game').replaceWith(msg);
    });
    return false;
  });
}
