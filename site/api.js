function toggleNav(el, id) {
  $(".resource").hide();
  $("#" + id).toggle();
  $(".endpoint a").removeClass("selected")
  $(el).addClass("selected")
}

$(document).ready(function() {
  $('.nav-tabs a').click(function (e) {
    e.preventDefault()
    $(this).tab('show')
  })
  $('.nav-tabs').each(function(t, e){ $(e).find("a:eq(0)").tab('show') });

})