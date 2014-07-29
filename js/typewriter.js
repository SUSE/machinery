/**
 *  by Manuele Carlini
 * text {String} - printing text
 * n {Number} - from what letter to start
 */
function typeWriter(text, n) {
  if (n < (text.length)) {
    $('.test').html(text.substring(0, n+1));
    n++;
    setTimeout(function() {
      typeWriter(text, n)
    }, 30);
  }
}
$(document).on("ready", function(e) {
  e.stopPropagation();
  
  var text = $('.test').data('text');
  
  typeWriter(text, 0);
});
/*
$('.start').click(function(e) {
  e.stopPropagation();
  
  var text = $('.test').data('text');
  
  typeWriter(text, 0);
});
*/