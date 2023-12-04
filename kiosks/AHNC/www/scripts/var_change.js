Shiny.addCustomMessageHandler("color_change", color_change);

function color_change(x) {
  $(".navbar-default").css('background-color', x)
}
